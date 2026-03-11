const functions = require("firebase-functions");
const admin = require("firebase-admin");
const stripe = require("stripe")("sk_test_51Rv1VdQ9CsoeqYGKIK1oocRS0bkZjnCxNUbLwllrxWBCc8ZeH75H3XE1Y1VkfOVSmWy11ZdtH5QAuoDVeAoSvIls00gBhRe2Ni");
const cors = require('cors')({origin: true});

if (!admin.apps.length) {
    admin.initializeApp();
}

// --- 1. WEBHOOK: Deblochează automat chat-ul când plata e finalizată ---
exports.stripeWebhook = functions.https.onRequest(async (req, res) => {
    const event = req.body;
    if (event.type === 'checkout.session.completed') {
        const session = event.data.object;
        const chatId = session.client_reference_id;
        if (chatId) {
            try {
                await admin.firestore().collection('chats').doc(chatId).update({
                    isSessionPaid: true
                });
                console.log(`✅ Sesiunea ${chatId} deblocată.`);
            } catch (error) {
                console.error("❌ Eroare Firestore:", error);
            }
        }
    }
    res.status(200).send("OK");
});

// --- 2. ONBOARDING: Profesorul își leagă contul bancar ---
exports.createStripeAccount = functions.https.onRequest((req, res) => {
    cors(req, res, async () => {
        try {
            const uid = req.body.uid;
            if (!uid) return res.status(400).send({ error: "UID lipsă" });

            const userRef = admin.firestore().collection('users').doc(uid);
            const userDoc = await userRef.get();
            let stripeAccountId = userDoc.data()?.stripeAccountId;

            if (!stripeAccountId) {
                const account = await stripe.accounts.create({ type: 'express' });
                stripeAccountId = account.id;
                await userRef.update({ stripeAccountId: stripeAccountId });
            }

            const accountLink = await stripe.accountLinks.create({
                account: stripeAccountId,
                refresh_url: 'https://imeditatii.web.app/success.html',
                return_url: 'https://imeditatii.web.app/success.html',
                type: 'account_onboarding',
            });

            return res.status(200).send({ url: accountLink.url });
        } catch (error) {
            return res.status(500).send({ error: error.message });
        }
    });
});

// --- 3. PLATA: Elevul plătește (Acum convertită la HTTP super-sigur) ---
exports.createCheckoutSession = functions.https.onRequest((req, res) => {
    cors(req, res, async () => {
        try {
            // Prelucrăm datele primite de la aplicația Flutter
            const { chatId, teacherId, amount } = req.body;

            // Protecție: Dacă nu am primit ID-ul, ne oprim aici și returnăm eroarea
            if (!teacherId) {
                return res.status(400).send({ error: "Eroare de comunicare: Nu am primit ID-ul profesorului pe server." });
            }

            const teacherDoc = await admin.firestore().collection('users').doc(teacherId).get();
            const stripeAccountId = teacherDoc.data()?.stripeAccountId;

            if (!stripeAccountId) {
                return res.status(400).send({ error: "Acest profesor nu a terminat configurarea contului Stripe." });
            }

            const appFee = Math.round(amount * 0.10);

            const session = await stripe.checkout.sessions.create({
                payment_method_types: ['card'],
                line_items: [{
                    price_data: {
                        currency: 'ron',
                        product_data: { name: 'Ședință Meditație' },
                        unit_amount: amount,
                    },
                    quantity: 1,
                }],
                mode: 'payment',
                client_reference_id: chatId,
                success_url: 'https://imeditatii.web.app/success.html',
                cancel_url: 'https://imeditatii.web.app/cancel.html',
                payment_intent_data: {
                    application_fee_amount: appFee,
                    transfer_data: {
                        destination: stripeAccountId,
                    },
                },
            });

            return res.status(200).send({ url: session.url });
        } catch (error) {
            console.error("Eroare Checkout Session:", error);
            return res.status(500).send({ error: error.message });
        }
    });
});

// --- 4. DASHBOARD LINK: Generează link-ul securizat pentru portofelul Stripe ---
exports.createStripeDashboardLink = functions.https.onRequest((req, res) => {
    cors(req, res, async () => {
        try {
            const uid = req.body.uid;
            if (!uid) return res.status(400).send({ error: "UID lipsă" });

            const userDoc = await admin.firestore().collection('users').doc(uid).get();
            const stripeAccountId = userDoc.data()?.stripeAccountId;

            if (!stripeAccountId) return res.status(400).send({ error: "Profesorul nu are un cont Stripe activ." });

            const loginLink = await stripe.accounts.createLoginLink(stripeAccountId);
            return res.status(200).send({ url: loginLink.url });
        } catch (error) {
            return res.status(500).send({ error: error.message });
        }
    });
});

// --- 5. VERIFICARE STATUS STRIPE ---
exports.verifyStripeStatus = functions.https.onRequest((req, res) => {
    cors(req, res, async () => {
        try {
            const uid = req.body.uid;
            if (!uid) return res.status(400).send({ error: "UID lipsă" });

            const userRef = admin.firestore().collection('users').doc(uid);
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