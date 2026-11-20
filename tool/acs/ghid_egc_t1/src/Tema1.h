#pragma once

#include <vector>

#include "components/simple_scene.h"
#include "lab_m1/Tema1/Card.h"
#include "lab_m1/Tema1/Player.h"


namespace m1
{
    class Tema1 : public gfxc::SimpleScene
    {
     public:
        Tema1();
        ~Tema1();

        void Init() override;

     private:
         void FrameStart() override;
         void Update(float deltaTimeSeconds) override;
         void FrameEnd() override;

         void OnInputUpdate(float deltaTime, int mods) override;
         void OnKeyPress(int key, int mods) override;
         void OnKeyRelease(int key, int mods) override;
         void OnMouseMove(int mouseX, int mouseY, int deltaX, int deltaY) override;
         void OnMouseBtnPress(int mouseX, int mouseY, int button, int mods) override;
         void OnMouseBtnRelease(int mouseX, int mouseY, int button, int mods) override;
         void OnMouseScroll(int mouseX, int mouseY, int offsetX, int offsetY) override;
         void OnWindowResize(int width, int height) override;
         void DrawRect(float x, float y, float width, float height, glm::vec3 color, glm::mat3 parent = glm::mat3(1));

         void DrawBoard();
         
         void FillDeck(std::vector<tema1::Card>& deck, bool isEnemy, int count);
         void TakeFromDeck(std::vector<tema1::Card>& deck, std::vector<tema1::Card>& cards);
         void PlayCard(std::vector<tema1::Card>& cards, int index);
         void ArrangeZone(std::vector<tema1::Card>& cards, tema1::Zone zone);
         void StartTurn(tema1::Player& player, std::vector<tema1::Card>& deck, std::vector<tema1::Card>& cards);
         void EndTurn();
         void EnemyTurn(float deltaTime);

         void DrawCard(const tema1::Card& card);
         void DrawHero(const tema1::Player& p, float y);
         void DrawMana(const tema1::Player& p, float y);
         void DrawArrow();
         bool IsLeftClick(int button);
         bool CanAttack(const tema1::Card& card);
         void Attack(tema1::Card& attacker, tema1::Card& target, tema1::Player& owner);
         void AttackHero(tema1::Card& attacker, tema1::Player& hero, tema1::Player& owner);
         void RemoveDead(std::vector<tema1::Card>& cards);
         void UpdateTimer(float deltaTime);
         void DrawTimer();

     protected:
         float screenW, screenH;
         float handH, heroZoneH, halfH;
         float cursorX, cursorY;
         int maxHandSize;
         int maxBoardSize;
         float enemyTimer;
         float enemyDelay;
         bool gameOver;
         bool isSilencing;
         float turnTime;
         float turnTimer;
         float timerX, timerW, timerH;
         float playerTimerY, enemyTimerY;

         float cardW, cardH, cardGap;

         float playerDeckX, playerDeckY;
         float enemyDeckX, enemyDeckY;

         float playerHandY, playerBoardY;
         float enemyHandY, enemyBoardY;

         float endButtonX, endButtonY;
         float endButtonW, endButtonH;

         float heroW, heroH;
         float heroX;
         float playerHeroY, enemyHeroY;

         std::vector<tema1::Card> playerDeck;
         std::vector<tema1::Card> enemyDeck;

         std::vector<tema1::Card> playerCards;
         std::vector<tema1::Card> enemyCards;

         tema1::Player player;
         tema1::Player enemy;
    };
}
