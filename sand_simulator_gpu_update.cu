//#include "gputk.h"
#include "sand_simulator_gpu_update.h"

static const char BLK_SIZE = 32;
static const char EMPTY = '.';
static const char SAND = '*';
static const int COARSE = 2;

__global__ void updateKernel(
    const char* privateGrid,
    char* grid,
    int height,
    int width) {

    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;

    if (x < width && y < height) {
        int idx = y * width + x;

        if (privateGrid[idx] == SAND) {  // Check the previous state from privateGrid
            // Down
            if (y + 1 < height && privateGrid[(y + 1) * width + x] == EMPTY) {
                grid[(y + 1) * width + x] = SAND;
                grid[idx] = EMPTY;
            }
            // Down-left or Down-right
            else if (y + 1 < height) {
                if (x - 1 >= 0 && privateGrid[(y + 1) * width + x - 1] == EMPTY) {
                    // Move down-left
                    grid[idx] = EMPTY;
                    grid[(y + 1) * width + x - 1] = SAND;
                }
                else if (x + 1 < width && privateGrid[(y + 1) * width + x + 1] == EMPTY) {
                    // Move down-right
                    grid[idx] = EMPTY;
                    grid[(y + 1) * width + x + 1] = SAND;
                }
            }
        }
    }
}

void updateSand(const char* privateGrid, char* grid, int height, int width) {
    // Allocate device memory
    char *d_privateGrid;
    char *d_grid;
    gpuErrchk( cudaMalloc((void**)&d_privateGrid, height * width) );
    gpuErrchk( cudaMalloc((void**)&d_grid, height * width) );

    // Copy to device
    gpuErrchk( cudaMemcpy((void*)d_privateGrid, (void*)privateGrid, height * width, cudaMemcpyHostToDevice) );
    gpuErrchk( cudaMemcpy((void*)d_grid, (void*)grid, height * width, cudaMemcpyHostToDevice) );

    // Define launch parameters
    dim3 _blockDim(BLK_SIZE, BLK_SIZE);
    dim3 _gridDim((width + BLK_SIZE * COARSE - 1) / BLK_SIZE * COARSE,
                  (height + BLK_SIZE * COARSE - 1) / BLK_SIZE * COARSE);

    // Run kernel
    updateKernel<<<_gridDim, _blockDim>>>(d_privateGrid, d_grid, height, width);
    gpuErrchk( cudaDeviceSynchronize() );

    // Copy result back to host
    gpuErrchk( cudaMemcpy((void*)grid, (void*)d_grid, height * width, cudaMemcpyDeviceToHost) );

    // Free device memory
    gpuErrchk( cudaFree(d_privateGrid) );
    gpuErrchk( cudaFree(d_grid) );
}
