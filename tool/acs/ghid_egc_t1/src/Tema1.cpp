#include "lab_m1/Tema1/Tema1.h"

#include <vector>
#include <iostream>
#include <ctime>
#include <cmath>

#include "lab_m1/Tema1/transform2D.h"
#include "lab_m1/Tema1/object2D.h"
#include "lab_m1/Tema1/shapes.h"

using namespace std;
using namespace m1;
using namespace tema1;


Tema1::Tema1()
{
}


Tema1::~Tema1()
{
}


void Tema1::Init()
{
    srand((unsigned)time(NULL));

    glm::ivec2 resolution = window->GetResolution();
    screenW = (float)resolution.x;
    screenH = (float)resolution.y;

    auto camera = GetSceneCamera();
    camera->SetOrthographic(0, screenW, 0, screenH, 0.01f, 800);
    camera->SetPosition(glm::vec3(0, 0, 50));
    camera->SetRotation(glm::vec3(0, 0, 0));
    camera->Update();
    GetCameraInput()->SetActive(false);


    Mesh* square = object2D::CreateSquare("square", glm::vec3(0, 0, 0), 1, glm::vec3(1, 1, 1), true);
    AddMeshToList(square);
    AddMeshToList(shapes::CreateCircle("circle"));
    AddMeshToList(shapes::CreateDiamond("diamond"));
    AddMeshToList(shapes::CreateTriangle("triangle"));
    AddMeshToList(shapes::CreatePlus("plus"));
    AddMeshToList(shapes::CreateStar("star"));
    AddMeshToList(shapes::CreateArrow("arrow"));
    AddMeshToList(shapes::CreateHeart("heart"));
    AddMeshToList(shapes::CreateSword("sword"));

    handH = screenH * 0.16f;
    heroZoneH = screenH * 0.16f;
    halfH = screenH * 0.18f;
    cursorX = 0;
    cursorY = 0;
    maxHandSize = 10;
    maxBoardSize = 7;
    enemyDelay = 1.0f;
    enemyTimer = 0;
    gameOver = false;
    isSilencing = false;

    cardH = handH * 0.8f;
    cardW = cardH * 0.7f;
    cardGap = cardW * 0.2f;

    playerHandY = (handH - cardH) / 2;
    playerBoardY = handH + heroZoneH + (halfH - cardH) / 2;
    enemyBoardY = screenH / 2 + (halfH - cardH) / 2;
    enemyHandY = screenH - handH + (handH - cardH) / 2;

    heroH = cardH;
    heroW = cardW;
    heroX = (screenW - heroW) / 2;
    playerHeroY = handH + (heroZoneH - heroH) / 2;
    enemyHeroY = screenH - handH - heroZoneH + (heroZoneH - heroH) / 2;

    playerDeckX = screenW - cardW - cardGap * 2;
    playerDeckY = playerHandY;
    enemyDeckX = playerDeckX;
    enemyDeckY = enemyHandY;

    endButtonW = cardW;
    endButtonH = cardH * 0.4f;
    endButtonX = playerDeckX;
    endButtonY = screenH / 2 - halfH / 2 - endButtonH / 2;

    turnTime = 30.0f;
    turnTimer = turnTime;
    timerW = endButtonW;
    timerH = (halfH - cardH) / 4;
    timerX = endButtonX;
    playerTimerY = screenH / 2 - (halfH - cardH) / 4 - timerH / 2;
    enemyTimerY = screenH / 2 + (halfH - cardH) / 4 - timerH / 2;

    FillDeck(playerDeck, false, 30);
    FillDeck(enemyDeck, true, 30);

    for (int i = 0; i < 5; i++) {
        TakeFromDeck(playerDeck, playerCards);
        TakeFromDeck(enemyDeck, enemyCards);
    }

    player.isMyTurn = true;
    player.mana = 0;
    player.maxMana = 0;
    enemy.mana = 0;
    enemy.maxMana = 0;
    StartTurn(player, playerDeck, playerCards);

}


void Tema1::FillDeck(vector<Card>& deck, bool isEnemy, int count)
{
    for (int i = 0; i < count; i++) {
        Card card;
        card.isEnemy = isEnemy;
        card.atk = 1 + rand() % 5;
        card.hp = 1 + rand() % 5;
        card.type = (CardType)(rand() % TYPE_COUNT);
        card.manaCost = GetTypeStyle(card.type).manaCost;
        card.effect = GetTypeStyle(card.type).effect;
        card.w = cardW;
        card.h = cardH;
        card.targetW = cardW;
        card.targetH = cardH;
        deck.push_back(card);
    }
}


void Tema1::TakeFromDeck(vector<Card>& deck, vector<Card>& cards)
{
    if (deck.empty()) {
        return;
    }

    int handCount = 0;
    for (int i = 0; i < (int)cards.size(); i++) {
        if (cards[i].zone == HAND) {
            handCount++;
        }
    }
    if (handCount >= maxHandSize) {
        return;
    }

    Card card = deck.back();
    deck.pop_back();

    card.zone = HAND;
    if (card.isEnemy) {
        card.x = enemyDeckX;
        card.y = enemyDeckY;
    } else {
        card.x = playerDeckX;
        card.y = playerDeckY;
    }

    cards.push_back(card);
    ArrangeZone(cards, HAND);
}


void Tema1::PlayCard(vector<Card>& cards, int index)
{
    cards[index].zone = BOARD;
    if (cards[index].isEnemy) {
        cards[index].round = enemy.round;
    } else {
        cards[index].round = player.round;
    }

    ArrangeZone(cards, HAND);
    ArrangeZone(cards, BOARD);
}


bool Tema1::CanAttack(const Card& card)
{
    bool isMyTurn = player.isMyTurn;
    int round = player.round;
    if (card.isEnemy) {
        isMyTurn = enemy.isMyTurn;
        round = enemy.round;
    }
    return card.zone == BOARD && isMyTurn && (card.round < round || card.effect == EFFECT_CHARGE) && !card.hasAttacked;
}


void Tema1::Attack(Card& attacker, Card& target, Player& owner)
{
    target.hp -= attacker.atk;
    attacker.hp -= target.atk;
    attacker.hasAttacked = true;
    attacker.isSelected = false;

    attacker.shakeTimer = 0.6f;
    target.shakeTimer = 0.6f;

    if (attacker.effect == EFFECT_LIFESTEAL) {
        owner.hp += attacker.atk;
    }

    RemoveDead(playerCards);
    RemoveDead(enemyCards);
}


void Tema1::AttackHero(Card& attacker, Player& hero, Player& owner)
{
    hero.hp -= attacker.atk;
    attacker.hasAttacked = true;
    attacker.isSelected = false;

    attacker.shakeTimer = 0.6f;
    hero.shakeTimer = 0.6f;

    if (attacker.effect == EFFECT_LIFESTEAL) {
        owner.hp += attacker.atk;
    }

    if (hero.hp <= 0) {
        gameOver = true;
    }
}


void Tema1::RemoveDead(vector<Card>& cards)
{
    for (int i = 0; i < (int)cards.size(); i++) {
        if (cards[i].zone == BOARD && cards[i].hp <= 0) {
            cards[i].zone = DEAD;
            cards[i].isSelected = false;
        }
    }
    ArrangeZone(cards, BOARD);
}


void Tema1::StartTurn(Player& player, vector<Card>& deck, vector<Card>& cards)
{
    player.isMyTurn = true;
    player.round++;

    if (player.maxMana < 10) {
        player.maxMana++;
    }
    player.mana = player.maxMana;
    turnTimer = turnTime;

    for (int i = 0; i < (int)cards.size(); i++) {
        cards[i].hasAttacked = false;
    }

    TakeFromDeck(deck, cards);
}


void Tema1::EndTurn()
{
    if (player.isMyTurn) {
        isSilencing = false;
        for (int i = 0; i < (int)playerCards.size(); i++) {
            playerCards[i].isSelected = false;
            playerCards[i].isDragged = false;
        }
        ArrangeZone(playerCards, HAND);
        player.isMyTurn = false;
        StartTurn(enemy, enemyDeck, enemyCards);
        enemyTimer = enemyDelay;
    } else {
        enemy.isMyTurn = false;
        StartTurn(player, playerDeck, playerCards);
    }
}


void Tema1::EnemyTurn(float deltaTime)
{
    enemyTimer -= deltaTime;
    if (enemyTimer > 0) {
        return;
    }
    enemyTimer = enemyDelay;

    int selected = -1;
    int boardCount = 0;
    vector<int> playable;
    vector<int> attackers;
    for (int i = 0; i < (int)enemyCards.size(); i++) {
        if (enemyCards[i].isSelected) {
            selected = i;
        }
        if (enemyCards[i].zone == BOARD) {
            boardCount++;
            if (CanAttack(enemyCards[i])) {
                attackers.push_back(i);
            }
        } else if (enemyCards[i].zone == HAND && enemyCards[i].manaCost <= enemy.mana) {
            playable.push_back(i);
        }
    }

    if (selected != -1) {
        int ok = 0;
        for (int i = 0; i < (int)playerCards.size(); i++) {
            if (playerCards[i].zone == BOARD && playerCards[i].effect == EFFECT_TANK) {
                ok = 1;
            }
        }

        vector<int> targets;
        for (int i = 0; i < (int)playerCards.size(); i++) {
            if (playerCards[i].zone == BOARD && (ok == 0 || playerCards[i].effect == EFFECT_TANK)) {
                targets.push_back(i);
            }
        }

        if (ok == 1) {
            Attack(enemyCards[selected], playerCards[targets[rand() % targets.size()]], enemy);
            return;
        }

        int pick = rand() % (targets.size() + 1);
        if (pick == (int)targets.size()) {
            AttackHero(enemyCards[selected], player, enemy);
        } else {
            Attack(enemyCards[selected], playerCards[targets[pick]], enemy);
        }
        return;
    }

    if (boardCount < maxBoardSize && !playable.empty()) {
        int index = playable[rand() % playable.size()];
        enemy.mana -= enemyCards[index].manaCost;
        PlayCard(enemyCards, index);

        if (enemyCards[index].effect == EFFECT_SILENCE) {
            vector<int> silenceTargets;
            for (int i = 0; i < (int)playerCards.size(); i++) {
                if (playerCards[i].zone == BOARD &&
                    (playerCards[i].effect == EFFECT_TANK || playerCards[i].effect == EFFECT_LIFESTEAL)) {
                    silenceTargets.push_back(i);
                }
            }
            if (!silenceTargets.empty()) {
                playerCards[silenceTargets[rand() % silenceTargets.size()]].effect = EFFECT_NONE;
            }
        }
        return;
    }

    if (!attackers.empty()) {
        int index = attackers[rand() % attackers.size()];
        enemyCards[index].isSelected = true;
        return;
    }

    EndTurn();
}


void Tema1::ArrangeZone(vector<Card>& cards, Zone zone)
{
    int n = 0;
    for (int i = 0; i < (int)cards.size(); i++) {
        if (cards[i].zone == zone) {
            n++;
        }
    }
    if (n == 0) {
        return;
    }

    float totalWidth = n * cardW + (n - 1) * cardGap;
    float startX = (screenW - totalWidth) / 2;

    int k = 0;
    for (int i = 0; i < (int)cards.size(); i++) {
        if (cards[i].zone != zone) {
            continue;
        }

        cards[i].targetX = startX + k * (cardW + cardGap);

        if (zone == HAND) {
            if (cards[i].isEnemy) {
                cards[i].targetY = enemyHandY;
            } else {
                cards[i].targetY = playerHandY;
            }
        } else {
            if (cards[i].isEnemy) {
                cards[i].targetY = enemyBoardY;
            } else {
                cards[i].targetY = playerBoardY;
            }
        }
        k++;
    }
}


void Tema1::DrawCard(const Card& card)
{
    if (card.zone == DEAD) {
        return;
    }

    float w = card.w;
    float h = card.h;
    float x = card.x - (w - cardW) / 2;
    float y = card.y - (h - cardH) / 2;

    glm::mat3 rotation = transform2D::Translate(x + w / 2, y + h / 2)
                         * transform2D::Rotate(card.angle)
                         * transform2D::Translate(-(x + w / 2), -(y + h / 2));

    float border = w * 0.04f;
    glm::vec3 borderColor = glm::vec3(0.05f, 0.05f, 0.05f);
    if (card.isSelected) {
        border = w * 0.08f;
        borderColor = glm::vec3(0.7f, 0.2f, 0.9f);
    } else if (CanAttack(card)) {
        border = w * 0.08f;
        borderColor = glm::vec3(0.2f, 1.0f, 0.4f);
    }
    DrawRect(x - border, y - border, w + 2 * border, h + 2 * border, borderColor, rotation);

    if (card.isEnemy && card.zone == HAND) {
        DrawRect(x, y, w, h, glm::vec3(0.45f, 0.2f, 0.1f), rotation);
        DrawRect(x + w * 0.2f, y + h * 0.2f, w * 0.6f, h * 0.6f, glm::vec3(0.6f, 0.35f, 0.15f), rotation);
        return;
    }
    TypeStyle style = GetTypeStyle(card.type);
    DrawRect(x, y, w, h, style.color, rotation);
    float shapeSize = w * 0.35f;
    glm::mat3 shapeMatrix = rotation
                            * transform2D::Translate(x + w / 2, y + h * 0.25f)
                            * transform2D::Scale(shapeSize, shapeSize);
    RenderMesh2D(meshes[style.shape], shapeMatrix, glm::vec3(1, 1, 1));

    float size = w * 0.12f;
    float space = size * 0.3f;
    float topY = y + h - space - size;

    int values[3] = { card.manaCost, card.atk, card.hp };
    string statShapes[3] = { "circle", "sword", "heart" };
    glm::vec3 statColors[3] = {
        glm::vec3(0.2f, 0.3f, 1.0f),
        glm::vec3(1.0f, 0.85f, 0.1f),
        glm::vec3(0.9f, 0.1f, 0.1f)
    };

    for (int s = 0; s < 3; s++) {
        float columnX = x + space + s * (size + space);
        for (int v = 0; v < values[s]; v++) {
            glm::mat3 statMatrix = rotation
                                   * transform2D::Translate(columnX + size / 2, topY - v * (size + space) + size / 2)
                                   * transform2D::Scale(size, size);
            RenderMesh2D(meshes[statShapes[s]], statMatrix, statColors[s]);
        }
    }
}


void Tema1::DrawHero(const Player& p, float y)
{
    glm::mat3 rotation = transform2D::Translate(heroX + heroW / 2, y + heroH / 2)
                         * transform2D::Rotate(p.angle)
                         * transform2D::Translate(-(heroX + heroW / 2), -(y + heroH / 2));

    float border = heroW * 0.04f;
    DrawRect(heroX - border, y - border, heroW + 2 * border, heroH + 2 * border, glm::vec3(0.05f, 0.05f, 0.05f), rotation);
    DrawRect(heroX, y, heroW, heroH, glm::vec3(0.75f, 0.60f, 0.25f), rotation);

    float symbolSize = heroW * 0.25f;
    glm::mat3 symbolMatrix = rotation
                             * transform2D::Translate(heroX + heroW / 2, y + heroH * 0.2f)
                             * transform2D::Scale(symbolSize, symbolSize);
    RenderMesh2D(meshes["circle"], symbolMatrix, glm::vec3(1, 1, 1));

    float size = heroW * 0.065f;
    float space = size * 0.3f;
    float topY = y + heroH - space - size;
    for (int i = 0; i < p.hp; i++) {
        int col = i / 10;
        int row = i % 10;
        float x = heroX + space + col * (size + space);
        float hy = topY - row * (size + space);
        glm::mat3 heartMatrix = rotation
                                * transform2D::Translate(x + size / 2, hy + size / 2)
                                * transform2D::Scale(size, size);
        RenderMesh2D(meshes["heart"], heartMatrix, glm::vec3(0.9f, 0.1f, 0.1f));
    }
}


void Tema1::DrawMana(const Player& p, float y)
{
    float size = heroH * 0.3f;
    float gap = size * 0.25f;
    float centerY = y + heroH / 2;
    float startX = heroX - heroW * 0.15f - 10 * size - 9 * gap;

    for (int i = 0; i < 10; i++) {
        glm::vec3 color;
        if (i < p.mana) {
            color = glm::vec3(0.2f, 0.4f, 1.0f);
        } else if (i < p.maxMana) {
            color = glm::vec3(1, 1, 1);
        } else {
            color = glm::vec3(0, 0, 0);
        }

        float cx = startX + i * (size + gap) + size / 2;
        glm::mat3 m = transform2D::Translate(cx, centerY) * transform2D::Scale(size, size);
        RenderMesh2D(meshes["diamond"], m, color);
    }
}

void Tema1::DrawArrow()
{
    for (int i = 0; i < (int)playerCards.size(); i++) {
        if (!playerCards[i].isSelected) {
            continue;
        }

        float sx = playerCards[i].x + cardW / 2;
        float sy = playerCards[i].y + cardH / 2;
        float dx = cursorX - sx;
        float dy = cursorY - sy;
        float length = sqrt(dx * dx + dy * dy);
        float angle = atan2(dy, dx);

        glm::mat3 m = transform2D::Translate(sx, sy)
                      * transform2D::Rotate(angle)
                      * transform2D::Scale(length, cardW * 0.6f);
        RenderMesh2D(meshes["arrow"], m, glm::vec3(0.9f, 0.2f, 0.2f));
    }
}


void Tema1::FrameStart()
{
    glClearColor(0.1f, 0.1f, 0.12f, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    glm::ivec2 resolution = window->GetResolution();
    glViewport(0, 0, resolution.x, resolution.y);


    glDisable(GL_DEPTH_TEST);
}


void Tema1::DrawRect(float x, float y, float width, float height, glm::vec3 color, glm::mat3 parent)
{
    glm::mat3 modelMatrix = parent;
    modelMatrix *= transform2D::Translate(x, y);
    modelMatrix *= transform2D::Scale(width, height);
    RenderMesh2D(meshes["square"], modelMatrix, color);
}


void Tema1::DrawBoard()
{
    DrawRect(0, 0, screenW, handH, glm::vec3(0.20f, 0.15f, 0.10f));
    DrawRect(0, screenH - handH, screenW, handH, glm::vec3(0.20f, 0.15f, 0.10f));

    DrawRect(0, handH, screenW, heroZoneH, glm::vec3(0.32f, 0.25f, 0.17f));
    DrawRect(0, screenH - handH - heroZoneH, screenW, heroZoneH, glm::vec3(0.32f, 0.25f, 0.17f));

    DrawRect(0, handH + heroZoneH, screenW, halfH, glm::vec3(0.25f, 0.40f, 0.25f));
    DrawRect(0, screenH / 2, screenW, halfH, glm::vec3(0.30f, 0.45f, 0.30f));

    DrawRect(0, screenH / 2 - 2, screenW, 4, glm::vec3(0.9f, 0.8f, 0.3f));
}


void Tema1::Update(float deltaTimeSeconds)
{
    UpdateTimer(deltaTimeSeconds);

    if (enemy.isMyTurn && !gameOver) {
        EnemyTurn(deltaTimeSeconds);
    }

    float speed = 8.0f;
    float step = min(1.0f, speed * deltaTimeSeconds);

    for (int i = 0; i < (int)playerCards.size(); i++) {
        if (playerCards[i].isDragged) {
            playerCards[i].targetX = cursorX - cardW / 2;
            playerCards[i].targetY = cursorY - cardH / 2;
        }

        float scale = 1;
        if (playerCards[i].isSelected) {
            scale = 1.3f;
        } else if (playerCards[i].isHovered) {
            scale = 1.15f;
        }
        playerCards[i].targetW = cardW * scale;
        playerCards[i].targetH = cardH * scale;

        playerCards[i].x += (playerCards[i].targetX - playerCards[i].x) * step;
        playerCards[i].y += (playerCards[i].targetY - playerCards[i].y) * step;
        playerCards[i].w += (playerCards[i].targetW - playerCards[i].w) * step;
        playerCards[i].h += (playerCards[i].targetH - playerCards[i].h) * step;

        playerCards[i].shakeTimer -= deltaTimeSeconds;
        if (playerCards[i].shakeTimer > 0) {
            if ((int)(playerCards[i].shakeTimer * 20) % 2 == 0) {
                playerCards[i].angle = 0.15f;
            } else {
                playerCards[i].angle = -0.15f;
            }
        } else {
            playerCards[i].shakeTimer = 0;
            playerCards[i].angle = 0;
        }
    }
    for (int i = 0; i < (int)enemyCards.size(); i++) {
        enemyCards[i].x += (enemyCards[i].targetX - enemyCards[i].x) * step;
        enemyCards[i].y += (enemyCards[i].targetY - enemyCards[i].y) * step;

        enemyCards[i].shakeTimer -= deltaTimeSeconds;
        if (enemyCards[i].shakeTimer > 0) {
            if ((int)(enemyCards[i].shakeTimer * 20) % 2 == 0) {
                enemyCards[i].angle = 0.15f;
            } else {
                enemyCards[i].angle = -0.15f;
            }
        } else {
            enemyCards[i].shakeTimer = 0;
            enemyCards[i].angle = 0;
        }
    }

    player.shakeTimer -= deltaTimeSeconds;
    if (player.shakeTimer > 0) {
        if ((int)(player.shakeTimer * 20) % 2 == 0) {
            player.angle = 0.15f;
        } else {
            player.angle = -0.15f;
        }
    } else {
        player.shakeTimer = 0;
        player.angle = 0;
    }

    enemy.shakeTimer -= deltaTimeSeconds;
    if (enemy.shakeTimer > 0) {
        if ((int)(enemy.shakeTimer * 20) % 2 == 0) {
            enemy.angle = 0.15f;
        } else {
            enemy.angle = -0.15f;
        }
    } else {
        enemy.shakeTimer = 0;
        enemy.angle = 0;
    }

    DrawBoard();

    float offset = cardW * 0.04f;
    for (int i = 0; i < min(3, (int)playerDeck.size()); i++) {
        DrawRect(playerDeckX + i * offset, playerDeckY + i * offset, cardW, cardH, glm::vec3(0.45f, 0.2f, 0.1f));
    }
    for (int i = 0; i < min(3, (int)enemyDeck.size()); i++) {
        DrawRect(enemyDeckX + i * offset, enemyDeckY - i * offset, cardW, cardH, glm::vec3(0.45f, 0.2f, 0.1f));
    }

    if (player.isMyTurn) {
        DrawRect(endButtonX, endButtonY, endButtonW, endButtonH, glm::vec3(0.2f, 0.75f, 0.3f));
    } else {
        DrawRect(endButtonX, endButtonY, endButtonW, endButtonH, glm::vec3(0.4f, 0.4f, 0.4f));
    }

    DrawTimer();

    DrawHero(player, playerHeroY);
    DrawHero(enemy, enemyHeroY);
    DrawMana(player, playerHeroY);
    DrawMana(enemy, enemyHeroY);

    for (int i = 0; i < (int)playerCards.size(); i++) {
        if (!playerCards[i].isDragged) {
            DrawCard(playerCards[i]);
        }
    }
    for (int i = 0; i < (int)enemyCards.size(); i++) {
        DrawCard(enemyCards[i]);
    }
    for (int i = 0; i < (int)playerCards.size(); i++) {
        if (playerCards[i].isDragged) {
            DrawCard(playerCards[i]);
        }
    }
    
    DrawArrow();

    if (gameOver) {
        glm::vec3 color = glm::vec3(0.8f, 0.15f, 0.15f);
        if (enemy.hp <= 0) {
            color = glm::vec3(0.2f, 0.75f, 0.3f);
        }
        DrawRect(screenW * 0.3f - 6, screenH * 0.4f - 6, screenW * 0.4f + 12, screenH * 0.2f + 12, glm::vec3(0.05f, 0.05f, 0.05f));
        DrawRect(screenW * 0.3f, screenH * 0.4f, screenW * 0.4f, screenH * 0.2f, color);
    }
}


void Tema1::FrameEnd()
{
}


void Tema1::OnInputUpdate(float deltaTime, int mods)
{
}


void Tema1::OnKeyPress(int key, int mods)
{
}


void Tema1::OnKeyRelease(int key, int mods)
{
}


void Tema1::OnMouseMove(int mouseX, int mouseY, int deltaX, int deltaY)
{
    glm::ivec2 res = window->GetResolution();
    cursorX = mouseX * screenW / res.x;
    cursorY = screenH - mouseY * screenH / res.y;

    for (int i = 0; i < (int)playerCards.size(); i++) {
        Card& card = playerCards[i];
        card.isHovered = (card.zone == HAND || card.zone == BOARD) &&
                         card.x <= cursorX && cursorX <= card.x + cardW &&
                         card.y <= cursorY && cursorY <= card.y + cardH;
    }
}


bool Tema1::IsLeftClick(int button)
{
    return button == 1;
}


void Tema1::OnMouseBtnPress(int mouseX, int mouseY, int button, int mods)
{
    if (!IsLeftClick(button)) {
        return;
    }

    if (!player.isMyTurn || gameOver) {
        return;
    }

    glm::ivec2 res = window->GetResolution();
    float mx = mouseX * screenW / res.x;
    float my = screenH - mouseY * screenH / res.y;
    cursorX = mx;
    cursorY = my;

    if (isSilencing) {
        for (int i = 0; i < (int)enemyCards.size(); i++) {
            Card& target = enemyCards[i];
            if (target.zone == BOARD &&
                (target.effect == EFFECT_TANK || target.effect == EFFECT_LIFESTEAL) &&
                target.x <= mx && mx <= target.x + cardW &&
                target.y <= my && my <= target.y + cardH) {
                target.effect = EFFECT_NONE;
                isSilencing = false;
                return;
            }
        }
        return;
    }

    if (endButtonX <= mx && mx <= endButtonX + endButtonW &&
        endButtonY <= my && my <= endButtonY + endButtonH) {
        EndTurn();
        return;
    }

    int selected = -1;
    for (int i = 0; i < (int)playerCards.size(); i++) {
        if (playerCards[i].isSelected) {
            selected = i;
        }
    }

    if (selected != -1) {
        int ok = 0;
        for (int i = 0; i < (int)enemyCards.size(); i++) {
            if (enemyCards[i].zone == BOARD && enemyCards[i].effect == EFFECT_TANK) {
                ok = 1;
            }
        }

        for (int i = 0; i < (int)enemyCards.size(); i++) {
            Card& target = enemyCards[i];
            if (target.zone == BOARD && (ok == 0 || target.effect == EFFECT_TANK) &&
                target.x <= mx && mx <= target.x + cardW &&
                target.y <= my && my <= target.y + cardH) {
                Attack(playerCards[selected], target, player);
                return;
            }
        }

        if (ok == 0 &&
            heroX <= mx && mx <= heroX + heroW &&
            enemyHeroY <= my && my <= enemyHeroY + heroH) {
            AttackHero(playerCards[selected], enemy, player);
            return;
        }
    }

    for (int i = 0; i < (int)playerCards.size(); i++) {
        Card& card = playerCards[i];
        if (card.zone == BOARD &&
            card.x <= mx && mx <= card.x + cardW &&
            card.y <= my && my <= card.y + cardH) {
            if (card.isSelected) {
                card.isSelected = false;
            } else if (CanAttack(card)) {
                for (int j = 0; j < (int)playerCards.size(); j++) {
                    playerCards[j].isSelected = false;
                }
                card.isSelected = true;
            }
            return;
        }
    }

    for (int i = (int)playerCards.size() - 1; i >= 0; i--) {
        Card& card = playerCards[i];
        if (card.zone == HAND &&
            card.x <= mx && mx <= card.x + cardW &&
            card.y <= my && my <= card.y + cardH) {
            card.isDragged = true;
            break;
        }
    }
}


void Tema1::OnMouseBtnRelease(int mouseX, int mouseY, int button, int mods)
{
    if (!IsLeftClick(button)) {
        return;
    }

    glm::ivec2 res = window->GetResolution();
    float mx = mouseX * screenW / res.x;
    float my = screenH - mouseY * screenH / res.y;

    int boardCount = 0;
    for (int i = 0; i < (int)playerCards.size(); i++) {
        if (playerCards[i].zone == BOARD) {
            boardCount++;
        }
    }

    for (int i = 0; i < (int)playerCards.size(); i++) {
        if (!playerCards[i].isDragged) {
            continue;
        }

        playerCards[i].isDragged = false;

        if (0 <= mx && mx <= screenW &&
            handH + heroZoneH <= my && my <= screenH / 2 &&
            boardCount < maxBoardSize &&
            playerCards[i].manaCost <= player.mana) {
            player.mana -= playerCards[i].manaCost;
            PlayCard(playerCards, i);

            if (playerCards[i].effect == EFFECT_SILENCE) {
                for (int j = 0; j < (int)enemyCards.size(); j++) {
                    if (enemyCards[j].zone == BOARD &&
                        (enemyCards[j].effect == EFFECT_TANK || enemyCards[j].effect == EFFECT_LIFESTEAL)) {
                        isSilencing = true;
                    }
                }
            }
        } else {
            ArrangeZone(playerCards, HAND);
        }
        break;
    }
}


void Tema1::OnMouseScroll(int mouseX, int mouseY, int offsetX, int offsetY)
{
}


void Tema1::OnWindowResize(int width, int height)
{
}
