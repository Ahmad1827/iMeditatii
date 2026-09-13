require("dotenv").config();
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const cors = require("cors")({ origin: true });

const stripeSecret = process.env.STRIPE_SECRET_KEY;
const stripePublishable = process.env.STRIPE_PUBLISHABLE_KEY;
const stripe = require("stripe")(stripeSecret);

if (!admin.apps.length) {
  admin.initializeApp();
}

// --- 1. PIPER GATEWAY: Create PaymentIntent with Connect Split ---
exports.createPaymentIntent = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    try {
      const { chatId, teacherId, amount, studentId } = req.body;

      if (!stripeSecret) {
        return res.status(500).send({
          error: "STRIPE_SECRET_KEY is missing on server. Check functions/.env",
        });
      }

      if (!chatId || !teacherId || !amount) {
        return res.status(400).send({
          error: "Missing required parameters (chatId, teacherId, amount).",
        });
      }

      // Check teacher's Stripe account status
      const teacherDoc = await admin.firestore().collection("users").doc(teacherId).get();
      const stripeAccountId = teacherDoc.data()?.stripeAccountId;

      const sessionId = "sess_" + Date.now();
      const appFee = Math.round(amount * 0.10); // 10% Platform fee

      const paymentIntentParams = {
        amount: Math.round(amount),
        currency: "ron",
        metadata: {
          chatId: chatId,
          teacherId: teacherId,
          studentId: studentId || "anonymous",
          sessionId: sessionId,
        },
      };

      // If the teacher has a connected Stripe account, route the 90% payout to them
      if (stripeAccountId && stripeAccountId.startsWith("acct_")) {
        paymentIntentParams.application_fee_amount = appFee;
        paymentIntentParams.transfer_data = {
          destination: stripeAccountId,
        };
      }

      let paymentIntent;
      try {
        paymentIntent = await stripe.paymentIntents.create(paymentIntentParams);
      } catch (stripeError) {
        console.error("Stripe API error:", stripeError);

        // Catch invalid or non-existent destination account IDs
        if (
          stripeError.message &&
          (stripeError.message.includes("No such destination") ||
            stripeError.code === "resource_missing" ||
            stripeError.raw?.code === "resource_missing")
        ) {
          return res.status(400).send({
            error:
              "Profesorul nu are contul Stripe configurat sau este invalid. Roagă profesorul să își configureze contul bancar din panoul său de profil.",
          });
        }

        return res.status(400).send({ error: stripeError.message });
      }

      // Initialize session in Firestore as pending
      await admin.firestore().collection("chats").doc(chatId).set(
        {
          activeSession: {
            sessionId: sessionId,
            status: "pending_payment",
            isPaid: false,
            amount: amount / 100,
            studentId: studentId,
            teacherId: teacherId,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          },
        },
        { merge: true }
      );

      return res.status(200).send({
        clientSecret: paymentIntent.client_secret,
        publishableKey: stripePublishable,
        sessionId: sessionId,
      });
    } catch (error) {
      console.error("PaymentIntent server error:", error);
      return res.status(500).send({ error: error.message });
    }
  });
});

// --- 2. WEBHOOK: Listens for Piper (PaymentIntent) ---
exports.stripeWebhook = functions.https.onRequest(async (req, res) => {
  const event = req.body;
  try {
    if (event.type === "payment_intent.succeeded") {
      const pi = event.data.object;
      const chatId = pi.metadata?.chatId;
      const sessionId = pi.metadata?.sessionId;

      if (chatId) {
        await admin.firestore().collection("chats").doc(chatId).set(
          {
            activeSession: {
              sessionId: sessionId,
              isPaid: true,
              status: "active",
              paidAt: admin.firestore.FieldValue.serverTimestamp(),
            },
            isSessionPaid: true,
          },
          { merge: true }
        );
        console.log(`✅ Piper PaymentIntent succeeded for chat: ${chatId}`);
      }
    }
  } catch (error) {
    console.error("Webhook error:", error);
  }
  res.status(200).send("OK");
});

// --- 3. ONBOARDING: Teacher connects Stripe Express ---
exports.createStripeAccount = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    try {
      const uid = req.body.uid;
      if (!uid) return res.status(400).send({ error: "UID lipsă" });

      const userRef = admin.firestore().collection("users").doc(uid);
      const userDoc = await userRef.get();
      let stripeAccountId = userDoc.data()?.stripeAccountId;

      if (!stripeAccountId) {
        const account = await stripe.accounts.create({ type: "express" });
        stripeAccountId = account.id;
        await userRef.update({ stripeAccountId: stripeAccountId });
      }

      const accountLink = await stripe.accountLinks.create({
        account: stripeAccountId,
        refresh_url: "https://ahmad1827.github.io/#/panou-profesor",
        return_url: "https://ahmad1827.github.io/#/panou-profesor",
        type: "account_onboarding",
      });

      return res.status(200).send({ url: accountLink.url });
    } catch (error) {
      return res.status(500).send({ error: error.message });
    }
  });
});

// --- 4. DASHBOARD LINK: Direct login to Stripe Express portal ---
exports.createStripeDashboardLink = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    try {
      const uid = req.body.uid;
      if (!uid) return res.status(400).send({ error: "UID lipsă" });

      const userDoc = await admin.firestore().collection("users").doc(uid).get();
      const stripeAccountId = userDoc.data()?.stripeAccountId;

      if (!stripeAccountId) {
        return res.status(400).send({ error: "Profesorul nu are un cont Stripe activ." });
      }

      const loginLink = await stripe.accounts.createLoginLink(stripeAccountId);
      return res.status(200).send({ url: loginLink.url });
    } catch (error) {
      return res.status(500).send({ error: error.message });
    }
  });
});

// --- 5. VERIFY STRIPE STATUS: Checks onboarding readiness ---
exports.verifyStripeStatus = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    try {
      const uid = req.body.uid;
      if (!uid) return res.status(400).send({ error: "UID lipsă" });

      const userRef = admin.firestore().collection("users").doc(uid);
      const userDoc = await userRef.get();
      const stripeAccountId = userDoc.data()?.stripeAccountId;

      if (!stripeAccountId) return res.status(200).send({ isReady: false });

      const account = await stripe.accounts.retrieve(stripeAccountId);
      const isReady = account.details_submitted && account.charges_enabled;

      await userRef.update({ isStripeActive: isReady });

      return res.status(200).send({ isReady: isReady });
    } catch (error) {
      return res.status(500).send({ error: error.message });
    }
  });
});