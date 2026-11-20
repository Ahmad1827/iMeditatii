#pragma once


namespace tema1
{
    struct Player
    {
        int hp = 30;
        int mana = 1;
        int maxMana = 1;
        int round = 0;
        bool isMyTurn = false;
        float angle = 0;
        float shakeTimer = 0;
    };
}
