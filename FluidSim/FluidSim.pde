/*
The MIT License (MIT)

Copyright (c) 2014-2018 Fournier Antoine - https://github.com/antoinefournier

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

// Fluid simulation.
// Left-click and move inside the red box to add smoke and forces.
//
// FluidGrid : class used to simulate the fluid
// FluidGridVisualizer : class used to render a FluidGrid

// This project use controlP5 for the GUI
// In processing 2.0+ use the menu Sketch/Import Library.../Add Library... to open the Library Manager
// then select the GUI category and download controlP5

import controlP5.*;

int SCREEN_WIDTH = 1024;
int SCREEN_HEIGHT = 768;

ControlP5 gui;
FluidGrid fluidGrid;
FluidGridVisualizer visualizer;

int mapSize;              // Size of the map, in cell on one axis (mapSize * mapSize => total number of cell)
boolean initWithDensity;  // If true some fluid is set in the map at the beginning of the simulation
boolean initWithForce;    // If true the map will be initialized with an initial force 
int initialForcePower;    // If initWithForce is true, this is the power of the force applied

float diffusion;          // Diffusion of the fluid
int fidelity;             // Add or reduce the number of iteration of the linear solver used by the simulation - 40 give goods results

boolean showCellGrid;     // If true, show the cell
boolean showVelocity;     // If true, show the vector representing the forces of the velocity field
boolean showDensity;      // If true, show a representation fo the fluid
int densityBrightness;    // Change the brightness of the density, a darker density helps to see the variations in the fluid


boolean isMousePressedInsideSimulation;


// GUI
Button start_Button;
Button reset_Button;
Slider mapSize_Slider;
CheckBox fillMapWithDensity_CheckBox;
CheckBox initalForce_CheckBox;
Slider initialForcePower_Slider;

Slider diffusion_Slider;
Slider fidelity_Slider;

CheckBox showCellGrid_CheckBox;
CheckBox showVelocity_CheckBox;
CheckBox showDensity_CheckBox;
Slider densityBrightness_Slider;

void settings()
{
  size(SCREEN_WIDTH, SCREEN_HEIGHT);
}


void setup()
{
  surface.setTitle("Fluid Simulation - Antoine Fournier - https://github.com/antoinefournier/Eulerian-Fluid-Simulation");

  mapSize           = 64;
  initWithDensity   = true;
  initWithForce     = true;
  initialForcePower = 20;

  diffusion         = 5.0;
  fidelity          = 40;

  showCellGrid      = false;
  showVelocity      = false;
  showDensity       = true;
  densityBrightness = 500;

  isMousePressedInsideSimulation = false;


  gui = new ControlP5(this);

  // Start button
  start_Button = gui.addButton("Start").setPosition(SCREEN_HEIGHT + 88, 50).setSize(80, 30);
  start_Button.getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER);

  // Reset button
  reset_Button = gui.addButton("Reset").setPosition(SCREEN_HEIGHT + 88, 50).setSize(80, 30);
  reset_Button.getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER);
  reset_Button.hide();



  // Map size slider
  mapSize_Slider = gui.addSlider("Map size").setPosition(SCREEN_HEIGHT + 30, 100).setSize(100, 20);
  mapSize_Slider.setValue(mapSize);
  mapSize_Slider.setRange(32, 196).setNumberOfTickMarks((int)(mapSize_Slider.getMax() - mapSize_Slider.getMin() + 1));
  mapSize_Slider.setSliderMode(Slider.FLEXIBLE);
  mapSize_Slider.setColorLabel(0);

  // Initial density CheckBox  
  fillMapWithDensity_CheckBox = gui.addCheckBox("Initialize with density").setPosition(SCREEN_HEIGHT + 30, 130).setSize(20, 20);
  fillMapWithDensity_CheckBox.addItem("Initialize with random density", 0);
  fillMapWithDensity_CheckBox.setColorLabel(0);
  if (initWithDensity) fillMapWithDensity_CheckBox.activate("Initialize with random density");

  // Initial force CheckBox
  initalForce_CheckBox = gui.addCheckBox("Initialize with force").setPosition(SCREEN_HEIGHT + 30, 160).setSize(20, 20);
  initalForce_CheckBox.addItem("Initialize with one force", 0);
  initalForce_CheckBox.setColorLabel(0);
  if (initWithForce) initalForce_CheckBox.activate("Initialize with one force");

  // Initial force power Slider
  initialForcePower_Slider = gui.addSlider("Initial force power").setPosition(SCREEN_HEIGHT + 30, 190).setSize(100, 20);
  initialForcePower_Slider.setValue(initialForcePower);
  initialForcePower_Slider.setRange(4, 500).setNumberOfTickMarks((int)(initialForcePower_Slider.getMax() - initialForcePower_Slider.getMin() + 1));
  initialForcePower_Slider.setColorLabel(0);



  // Fluid diffusion Slider
  diffusion_Slider = gui.addSlider("Fluid diffusion").setPosition(SCREEN_HEIGHT + 30, 300).setSize(100, 20);
  diffusion_Slider.setValue(diffusion);
  diffusion_Slider.setRange(0.1, 20.0).setNumberOfTickMarks((int)((diffusion_Slider.getMax() - diffusion_Slider.getMin()) * 10 + 1));
  diffusion_Slider.setColorLabel(0);

  // Simulation fidelity Slider
  fidelity_Slider = gui.addSlider("Simulation fidelity").setPosition(SCREEN_HEIGHT + 30, 330).setSize(100, 20);
  fidelity_Slider.setValue(fidelity);
  fidelity_Slider.setRange(1, 100).setNumberOfTickMarks((int)(fidelity_Slider.getMax() - fidelity_Slider.getMin() + 1));
  fidelity_Slider.setColorLabel(0);



  // Show grid CheckBox
  showCellGrid_CheckBox = gui.addCheckBox("Show Grid CheckBox").setPosition(SCREEN_HEIGHT + 30, 420).setSize(20, 20);
  showCellGrid_CheckBox.addItem("Show Grid", 0);
  showCellGrid_CheckBox.setColorLabel(0);
  if (showCellGrid) showCellGrid_CheckBox.activate("Show Grid");

  // Show velocity field CheckBox
  showVelocity_CheckBox = gui.addCheckBox("Show Velocity Field CheckBox").setPosition(SCREEN_HEIGHT + 30, 450).setSize(20, 20);
  showVelocity_CheckBox.addItem("Show Velocity Field", 0);
  showVelocity_CheckBox.setColorLabel(0);
  if (showVelocity) showVelocity_CheckBox.activate("Show Velocity Field");

  // Show density CheckBox
  showDensity_CheckBox = gui.addCheckBox("Show Density CheckBox").setPosition(SCREEN_HEIGHT + 30, 480).setSize(20, 20);
  showDensity_CheckBox.addItem("Show Density", 0);
  showDensity_CheckBox.setColorLabel(0);
  if (showDensity) showDensity_CheckBox.activate("Show Density");

  // Density brightness slider
  densityBrightness_Slider = gui.addSlider("Density brightness").setPosition(SCREEN_HEIGHT + 30, 510).setSize(100, 20);
  densityBrightness_Slider.setValue(densityBrightness);
  densityBrightness_Slider.setRange(0, 750).setNumberOfTickMarks((int)(densityBrightness_Slider.getMax() - densityBrightness_Slider.getMin() + 1));
  densityBrightness_Slider.setColorLabel(0);
}

void draw()  
{
  background(255);

  float dt = (int)(10000.0f / frameRate) / 10000.0f;

  fill(0);
  text("Frame rate: " + int(frameRate) + " (" + dt + " seconds)", 10, 20);


  text("Mouse click", SCREEN_HEIGHT + 10, 600);
  text("Add density at the mouse position", SCREEN_HEIGHT + 20, 620);

  text("Mouse move while button pressed", SCREEN_HEIGHT + 10, 650);
  text("Add density and forces", SCREEN_HEIGHT + 20, 670);

  // Add a forces to the simulation
  if (isMousePressedInsideSimulation == true && visualizer != null && fluidGrid != null)
    addForce();

  if (fluidGrid != null)
    fluidGrid.update(dt);
  if (visualizer != null)
    visualizer.render();
}

void startSimulation()
{
  fluidGrid = new FluidGrid(mapSize, initWithDensity, initWithForce, initialForcePower);
  fluidGrid.setDiffusion(diffusion);
  fluidGrid.setFidelity(fidelity);

  // Place the visual representation of the grid at the center of the screen
  int offset = 25;
  int maxSize = SCREEN_HEIGHT - offset * 2;
  int sizeCell1 = SCREEN_HEIGHT / mapSize;
  int sizeCell2 = maxSize / mapSize;
  int sizeCell = (sizeCell1 * mapSize > maxSize) ? sizeCell2 : sizeCell1;
  int pos = (SCREEN_HEIGHT - (sizeCell * mapSize)) / 2;

  visualizer = new FluidGridVisualizer(fluidGrid, pos, pos, sizeCell);

  visualizer.drawCellGrid(showCellGrid);
  visualizer.drawVelocityField(showVelocity);
  visualizer.drawDensity(showDensity);

  visualizer.setDensityBrightness(750 - densityBrightness);

  reset_Button.show();
  start_Button.hide();
  mapSize_Slider.hide();
  fillMapWithDensity_CheckBox.hide();
  initalForce_CheckBox.hide();
  initialForcePower_Slider.hide();
}

void endSimulation()
{
  fluidGrid = null;
  visualizer = null;

  reset_Button.hide();
  start_Button.show();
  mapSize_Slider.show();
  fillMapWithDensity_CheckBox.show();
  initalForce_CheckBox.show();
  initialForcePower_Slider.show();
}

void addForce()
{
  // Get the delta movement of the mouse from the last frame
  int[] cell = visualizer.getCell(pmouseX, pmouseY);
  int x = cell[0];
  int y = cell[1];

  if (x == -1 || y == -1)
    return;

  int dirX = -(pmouseX - mouseX);
  int dirY = -(pmouseY - mouseY);

  float powerX = (float)(10 * dirX / frameRate);
  float powerY = (float)(10 * dirY / frameRate);
  float density = (3.0f / frameRate) * (1 + sqrt(dirX * dirX + dirY * dirY) / 3);

  fluidGrid.addForceAndDensity(cell[0], cell[1], powerX, powerY, density);
}

void mousePressed()
{
  if (visualizer == null)
    return;

  if (visualizer.isInside(mouseX, mouseY))
    isMousePressedInsideSimulation = true;
}

void mouseReleased()
{
  isMousePressedInsideSimulation = false;
}

// Event sent by ControlP5
void controlEvent(ControlEvent _e)
{
  // CheckBox
  if (_e.isFrom(fillMapWithDensity_CheckBox))
  {
    initWithDensity = (fillMapWithDensity_CheckBox.getArrayValue()[0] != 0);
    return;
  }

  // CheckBox
  if (_e.isFrom(initalForce_CheckBox))
  {
    initWithForce = (initalForce_CheckBox.getArrayValue()[0] != 0);
    return;
  }

  // CheckBox
  if (_e.isFrom(showCellGrid_CheckBox))
  {
    showCellGrid = (showCellGrid_CheckBox.getArrayValue()[0] != 0);
    if (visualizer != null)
      visualizer.drawCellGrid(showCellGrid);
    return;
  }

  // CheckBox
  if (_e.isFrom(showVelocity_CheckBox))
  {
    showVelocity = (showVelocity_CheckBox.getArrayValue()[0] != 0);
    if (visualizer != null)
      visualizer.drawVelocityField(showVelocity);
    return;
  }

  // CheckBox
  if (_e.isFrom(showDensity_CheckBox))
  {
    showDensity = (showDensity_CheckBox.getArrayValue()[0] != 0);
    if (visualizer != null)
      visualizer.drawDensity(showDensity);
    return;
  }

  // Button
  if (_e.getController() == start_Button)
  {
    startSimulation();
    return;
  }

  // Button
  if (_e.getController() == reset_Button)
  {
    endSimulation();
    return;
  }

  // Slider
  if (_e.getController() == mapSize_Slider)
  {
    mapSize = (int)mapSize_Slider.getValue();
    return;
  }


  // Slider
  if (_e.getController() == diffusion_Slider)
  {
    diffusion = diffusion_Slider.getValue();
    if (fluidGrid != null)
      fluidGrid.setDiffusion(diffusion);
    return;
  }

  // Slider
  if (_e.getController() == fidelity_Slider)
  {
    fidelity = (int)fidelity_Slider.getValue();
    if (fluidGrid != null)
      fluidGrid.setDiffusion(fidelity);
    return;
  }

  // Slider
  if (_e.getController() == densityBrightness_Slider)
  {
    densityBrightness = (int)densityBrightness_Slider.getValue();
    if (visualizer != null)
      visualizer.setDensityBrightness(750 - densityBrightness);
    return;
  }

  // Slider
  if (_e.getController() == initialForcePower_Slider)
  {
    initialForcePower = (int)initialForcePower_Slider.getValue();
    return;
  }
}
