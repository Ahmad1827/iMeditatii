#include "lab_m1/Tema1/shapes.h"

#include <vector>
#include <cmath>

#include "core/engine.h"
#include "utils/gl_utils.h"

using namespace std;


Mesh* tema1::shapes::CreatePlus(const string& name)
{
    glm::vec3 white(1, 1, 1);
    float t = 0.15f;

    vector<VertexFormat> vertices =
    {
        VertexFormat(glm::vec3(-0.5f, -t, 0), white),
        VertexFormat(glm::vec3( 0.5f, -t, 0), white),
        VertexFormat(glm::vec3( 0.5f,  t, 0), white),
        VertexFormat(glm::vec3(-0.5f,  t, 0), white),

        VertexFormat(glm::vec3(-t, -0.5f, 0), white),
        VertexFormat(glm::vec3( t, -0.5f, 0), white),
        VertexFormat(glm::vec3( t,  0.5f, 0), white),
        VertexFormat(glm::vec3(-t,  0.5f, 0), white),
    };

    vector<unsigned int> indices =
    {
        0, 1, 2,
        0, 2, 3,

        4, 5, 6,
        4, 6, 7,
    };

    Mesh* mesh = new Mesh(name);
    mesh->InitFromData(vertices, indices);
    return mesh;
}


Mesh* tema1::shapes::CreateTriangle(const string& name)
{
    glm::vec3 white(1, 1, 1);

    vector<VertexFormat> vertices =
    {
        VertexFormat(glm::vec3(-0.5f, -0.5f, 0), white),
        VertexFormat(glm::vec3( 0.5f, -0.5f, 0), white),
        VertexFormat(glm::vec3( 0.0f,  0.5f, 0), white),
    };

    vector<unsigned int> indices =
    {
        0, 1, 2,
    };

    Mesh* mesh = new Mesh(name);
    mesh->InitFromData(vertices, indices);
    return mesh;
}


Mesh* tema1::shapes::CreateDiamond(const string& name)
{
    glm::vec3 white(1, 1, 1);

    vector<VertexFormat> vertices =
    {
        VertexFormat(glm::vec3( 0.0f,  0.5f, 0), white),
        VertexFormat(glm::vec3( 0.5f,  0.0f, 0), white),
        VertexFormat(glm::vec3( 0.0f, -0.5f, 0), white),
        VertexFormat(glm::vec3(-0.5f,  0.0f, 0), white),
    };

    vector<unsigned int> indices =
    {
        0, 3, 2,
        0, 2, 1,
    };

    Mesh* mesh = new Mesh(name);
    mesh->InitFromData(vertices, indices);
    return mesh;
}


Mesh* tema1::shapes::CreateStar(const string& name)
{
    glm::vec3 white(1, 1, 1);
    float pi = 3.14159265f;
    int points = 10;

    vector<VertexFormat> vertices;
    vector<unsigned int> indices;

    vertices.push_back(VertexFormat(glm::vec3(0, 0, 0), white));

    for (int i = 0; i < points; i++) {
        float angle = pi / 2 + i * 2 * pi / points;
        float r = 0.2f;
        if (i % 2 == 0) {
            r = 0.5f;
        }
        vertices.push_back(VertexFormat(glm::vec3(r * cos(angle), r * sin(angle), 0), white));
    }

    for (int i = 0; i < points; i++) {
        indices.push_back(0);
        indices.push_back(i + 1);
        indices.push_back((i + 1) % points + 1);
    }

    Mesh* mesh = new Mesh(name);
    mesh->InitFromData(vertices, indices);
    return mesh;
}


Mesh* tema1::shapes::CreateCircle(const string& name, int segments)
{
    glm::vec3 white(1, 1, 1);
    float pi = 3.14159265f;

    vector<VertexFormat> vertices;
    vector<unsigned int> indices;

    vertices.push_back(VertexFormat(glm::vec3(0, 0, 0), white));

    for (int i = 0; i < segments; i++) {
        float angle = 2 * pi * i / segments;
        vertices.push_back(VertexFormat(glm::vec3(0.5f * cos(angle), 0.5f * sin(angle), 0), white));
    }

    for (int i = 0; i < segments; i++) {
        indices.push_back(0);
        indices.push_back(i + 1);
        indices.push_back((i + 1) % segments + 1);
    }

    Mesh* mesh = new Mesh(name);
    mesh->InitFromData(vertices, indices);
    return mesh;
}

Mesh* tema1::shapes::CreateArrow(const string& name)
{
    glm::vec3 white(1, 1, 1);

    vector<VertexFormat> vertices =
    {
        VertexFormat(glm::vec3(0.0f,  -0.15f, 0), white),
        VertexFormat(glm::vec3(0.75f, -0.15f, 0), white),
        VertexFormat(glm::vec3(0.75f,  0.15f, 0), white),
        VertexFormat(glm::vec3(0.0f,   0.15f, 0), white),

        VertexFormat(glm::vec3(0.75f, -0.5f, 0), white),
        VertexFormat(glm::vec3(1.0f,   0.0f, 0), white),
        VertexFormat(glm::vec3(0.75f,  0.5f, 0), white),
    };

    vector<unsigned int> indices =
    {
        0, 1, 2,
        0, 2, 3,

        4, 5, 6,
    };

    Mesh* mesh = new Mesh(name);
    mesh->InitFromData(vertices, indices);
    return mesh;
}

Mesh* tema1::shapes::CreateHeart(const string& name, int segments)
{
    glm::vec3 white(1, 1, 1);
    float pi = 3.14159265f;
    float a = 0.38f;
    float offsetY = 0.875f * a;

    vector<VertexFormat> vertices;
    vector<unsigned int> indices;

    vertices.push_back(VertexFormat(glm::vec3(0, offsetY, 0), white));

    for (int i = 0; i < segments; i++) {
        float angle = 2 * pi * i / segments;
        float r = a * (1 - cos(angle));
        vertices.push_back(VertexFormat(glm::vec3(-r * sin(angle), r * cos(angle) + offsetY, 0), white));
    }

    for (int i = 0; i < segments; i++) {
        indices.push_back(0);
        indices.push_back(i + 1);
        indices.push_back((i + 1) % segments + 1);
    }

    Mesh* mesh = new Mesh(name);
    mesh->InitFromData(vertices, indices);
    return mesh;
}


Mesh* tema1::shapes::CreateSword(const string& name, int segments)
{
    glm::vec3 white(1, 1, 1);
    float pi = 3.14159265f;
    float a = 0.3f;
    float b = 0.1f;
    float c = 1.05f;
    int n = 3;
    int m = 2;
    float scale = 0.38f;
    float scaleX = 0.9f;
    float offsetY = -0.385f;

    vector<VertexFormat> vertices;
    vector<unsigned int> indices;

    vertices.push_back(VertexFormat(glm::vec3(0, offsetY, 0), white));

    for (int i = 0; i < segments; i++) {
        float angle = 2 * pi * i / segments;
        float r = a + b * sin(n * angle) / (c + cos(m * angle));
        vertices.push_back(VertexFormat(glm::vec3(scaleX * r * cos(angle), -scale * r * sin(angle) + offsetY, 0), white));
    }

    for (int i = 0; i < segments; i++) {
        indices.push_back(0);
        indices.push_back(i + 1);
        indices.push_back((i + 1) % segments + 1);
    }

    Mesh* mesh = new Mesh(name);
    mesh->InitFromData(vertices, indices);
    return mesh;
}
