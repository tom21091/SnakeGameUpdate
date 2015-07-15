#include <PICxel.h>

typedef struct snode{
  uint8_t en;
  uint8_t count;
  int *hue;
  uint8_t sat;
  uint8_t val;
  struct snode* tailptr;
}SNODE;

#define UP 0        //yellow, 34
#define LEFT 1      //blue, 35
#define DOWN 2      //green, 36
#define RIGHT 3     //brown, 37

#define number_of_LEDs 900
#define LED_pin 3
#define millisecond_delay 1

PICxel strip(number_of_LEDs, LED_pin, HSV);

uint8_t head[2]={6,1};
uint8_t food[2];
uint8_t dir=RIGHT;
uint8_t lastdir=RIGHT;
uint8_t length=6;
snode grid[30][30];
int lastupdate;
uint8_t lastbuf[2];
static int i,j;
uint16_t difficulty=100;
int snakehue=500;

int backhue=700;

int foodhue=214;

int backupdate=0;

const uint8_t snakebrightness=200;
const uint8_t backbrightness=15;

const uint8_t refreshrate=15;

int time =0;
int timeDif = 0;


#define CHANGE_HEAP_SIZE(size) __asm__ volatile ("\t.globl _min_heap_size\n\t.equ _min_heap_size, " #size "\n")

CHANGE_HEAP_SIZE(0x2000);

extern __attribute__((section("linker_defined"))) char _heap;
extern __attribute__((section("linker_defined"))) char _min_heap_size;

snode* snake_ptr;
char changed_flag = 0;

void setup() {
  //start the serial monitor to show the high score when the game ends
  Serial.begin(115200);
  
  randomSeed(analogRead(A3));
  
  strip.begin();
  reset_grid();
  lastupdate=millis();
  backupdate=millis();  
}

void loop() {

switch ( a ) {
  case b:
    // Code
    break;
  case c:
  // Code
  break;
default:
  // Code
  break;
}


  
  //Buttons connected to 34 (yellow UP) - 35 (blue LEFT) - 36 (green DOWN) - 37 (brown RIGHT)
  //check up
  if(digitalRead(34)){
    if (digitalRead(35)&&digitalRead(36)&&digitalRead(37)){
      reset_grid();
    }
    if(lastdir!=UP)
      dir=DOWN;
  }
  
  //check left
  else if(digitalRead(35)){
    if(lastdir!=RIGHT)
      dir=LEFT;
  }
  
  //check down
  else if(digitalRead(36)){
    if(lastdir!=DOWN)
      dir=UP;
  }

  //check right
  else if(digitalRead(37)){
    if(lastdir!=LEFT)
      dir=RIGHT;
  }
  
  if (millis()-lastupdate>=difficulty){//Update every [difficulty] ms
    lastupdate=millis();
    //moved to changed_flag if statement
    //update();
    
    lastdir=dir;
    snakehue+=5;
    if (snakehue>=1535){
      snakehue=0;
    }

    //background has changed so set flag
    changed_flag = 1;
  }

  //update background color at a certain rate
  if (millis()-backupdate>=refreshrate){
    backupdate=millis();
    backhue+=2;
    if (backhue>=1535){
      backhue=0;
    }

    //background has changed so set flag
    changed_flag = 1;
  }
  
  //only update the array and refresh LEDs if the state has changed
  if(changed_flag == 1){
    update();
    store_array();
    strip.refreshLEDs();
    //clear flag
    changed_flag = 0;
  }
}


//Updates the 2D snake grid array in memory
void update(){
  lastbuf= {head[0], head[1]};
  switch (dir){
    case UP:
      if (head[1]==0){reset_grid(); return;}  //if the head runs into the ceiling, you die
      else head[1]--;
      break;
    case DOWN:
      if (head[1]==29){reset_grid(); return;}  //if the head runs into the floor, you die
      else head[1]++;
      break;
    case RIGHT:
      if(head[0]==29){reset_grid(); return;}  //if the head runs into the right wall, you die
      else head[0]++;
      break;
    case LEFT:
      if(head[0]==0){reset_grid(); return;}  //if the head runs into the left wall, you die
      else head[0]--;
      break;
  }
    snake_ptr=&grid[head[0]][head[1]];
    if (snake_ptr->en==1){reset_grid(); return;}//Ran into self!
    if (snake_ptr->en==2){//FOOD!
      length+=2;
      difficulty-=2;
      spawn_food();
    }
    snake_ptr->en=1;
    snake_ptr->count=1;
    snake_ptr->hue=&snakehue;
    snake_ptr->sat=255;
    snake_ptr->val=snakebrightness;
    snake_ptr->tailptr= &grid[lastbuf[0]][lastbuf[1]];
    while(snake_ptr->tailptr){
      if (snake_ptr->tailptr->count<length){//Next segment count is less than length, it lives
        //Serial.println(snake_ptr->count, DEC);
        snake_ptr->tailptr->count++;//Decrement tailptr count
      }
      else{//Next segment count is length so it dies
      //Serial.println("Killed");
        snake_ptr->tailptr->en=0;
        snake_ptr->tailptr->count=0;
        snake_ptr->tailptr->hue=&backhue;
        snake_ptr->tailptr->sat=255;
        snake_ptr->tailptr->val=backbrightness;
        snake_ptr->tailptr=NULL;//Remove tailptr of current segment
        break;
      }
      snake_ptr=snake_ptr->tailptr;
    }
}

//Stores the 2D snake array into the strip library's memory
void store_array(){
 int s = 0;
    for(i = 29; i >= 0 ; i--){
      if(i % 2 == 0){ //is even
       for(j = 0; j < 30; j++){
         strip.HSVsetLEDColor(s, (*grid[i][j].hue + grid[i][j].count*5)%1535, grid[i][j].sat, grid[i][j].val);
         s++;
       }
      }
      else{
       for(j = 29; j >= 0; j--){
         strip.HSVsetLEDColor(s, (*grid[i][j].hue + grid[i][j].count*5)%1535, grid[i][j].sat, grid[i][j].val);
         s++;
       } 
      }
    }
}

//Randomly spawns an apple on the 2D grid
void spawn_food(){
  //food={10,1};
  food={random(30),random(30)};
  while (grid[food[0]][food[1]].en!=0){
    food={random(30),random(30)};
  }
  grid[food[0]][food[1]].en=2;
  grid[food[0]][food[1]].count=0;
  grid[food[0]][food[1]].hue=&foodhue;
  grid[food[0]][food[1]].sat=255;
  grid[food[0]][food[1]].val=snakebrightness;
}

//Resets the grid, snake is at top left, all else are reset to blank
void reset_grid(){
  //if the length is not the starting value, print/send off the high score
  if(length != 6){Serial.println(int(length));}
  
  for (i=0;i<30;i++){
    for(j=0; j<30;j++){
      grid[i][j].en=0;
      grid[i][j].count=0;
      grid[i][j].hue=&backhue;
      grid[i][j].sat=255;
      grid[i][j].val=backbrightness;
      grid[i][j].tailptr=NULL;
    }
  }
  dir= RIGHT;
  head={6,1};
  length=6;
  for (i=6; i>=1; i--){
    snake_ptr=&grid[i][1];
    snake_ptr->en=1;
    snake_ptr->sat=255;
    snake_ptr->val=snakebrightness;
    snake_ptr->hue=&snakehue;
    snake_ptr->count=7-i;
    snake_ptr->tailptr=&grid[i-1][1];
    snake_ptr=snake_ptr->tailptr;
  }  
  spawn_food();
  difficulty=100;
}

