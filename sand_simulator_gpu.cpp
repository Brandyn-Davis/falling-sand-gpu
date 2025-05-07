#include "World.h"

#include <iostream>
#include <cstdlib>
#include <cmath>
#include <chrono>
#include <thread>

#define WIDTH 40
#define HEIGHT 20

int main() {
    char privateGrid[HEIGHT * WIDTH];
    char grid[HEIGHT * WIDTH];

    World world(HEIGHT, WIDTH, privateGrid, grid);
    int frame = 0;

    while (!world.isFull()) {
        world.clearScreen();

        world.update();
        world.printGrid();

        std::this_thread::sleep_for(std::chrono::milliseconds(100));
        ++frame;

        // Spawn new sand every few frames (every frame in this case)
        if (frame % 1 == 0) {
            world.spawnSand(rand() % WIDTH);  // Spawn sand at a random column
        }

        world.swapGrids();  // Swap the grids after updating
    }

    std::cout << "The grid is full!" << std::endl;
    return 0;
}
