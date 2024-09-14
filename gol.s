.section ".word"
   /* Game state memory locations */
  .equ CURR_STATE, 0x90001000       /* Current state of the game */
  .equ GSA_ID, 0x90001004           /* ID of the GSA holding the current state */
  .equ PAUSE, 0x90001008            /* Is the game paused or running */
  .equ SPEED, 0x9000100C            /* Current speed of the game */
  .equ CURR_STEP,  0x90001010       /* Current step of the game */
  .equ SEED, 0x90001014             /* Which seed was used to start the game */
  .equ GSA0, 0x90001018             /* Game State Array 0 starting address */
  .equ GSA1, 0x90001058             /* Game State Array 1 starting address */
  .equ CUSTOM_VAR_START, 0x90001200 /* Start of free range of addresses for custom vars */
  .equ CUSTOM_VAR_END, 0x90001300   /* End of free range of addresses for custom vars */
  .equ RANDOM, 0x40000000           /* Random number generator address */
  .equ LEDS, 0x50000000             /* LEDs address */
  .equ SEVEN_SEGS, 0x60000000       /* 7-segment display addresses */
  .equ BUTTONS, 0x70000004          /* Buttons address */

  /* States */
  .equ INIT, 0
  .equ RAND, 1
  .equ RUN, 2

  /* Colors (0bBGR) */
  .equ RED, 0x100
  .equ BLUE, 0x400

  /* Buttons */
  .equ JT, 0x10
  .equ JB, 0x8
  .equ JL, 0x4
  .equ JR, 0x2
  .equ JC, 0x1
  .equ BUTTON_2, 0x80
  .equ BUTTON_1, 0x20
  .equ BUTTON_0, 0x40

  /* LED selection */
  .equ ALL, 0xF

  /* Constants */
  .equ N_SEEDS, 4           /* Number of available seeds */
  .equ N_GSA_LINES, 10       /* Number of GSA lines */
  .equ N_GSA_COLUMNS, 12    /* Number of GSA columns */
  .equ MAX_SPEED, 10        /* Maximum speed */
  .equ MIN_SPEED, 1         /* Minimum speed */
  .equ PAUSED, 0x00         /* Game paused value */
  .equ RUNNING, 0x01        /* Game running value */

.section ".text.init"
  .globl main

main:
  li sp, CUSTOM_VAR_END /* Set stack pointer, grows downwards */

  li t1, 10        /*Set game speed*/
  li t2, SPEED
  sb t1, 0(t2)

.L_main:
  li a0, 0xFBBA
  li a1, 3
  jal set_gsa

  li a0, 0x3251
  li a1, 1
  jal set_gsa

  li a0, 0x9012
  li a1, 6
  jal set_gsa

  li t1, 1
  li t2, GSA_ID
  sw t1, 0(t2)

  li a0, 1
  jal get_gsa

  li t2, GSA_ID
  sw x0, 0(t2)

  li a0, 1
  jal get_gsa

  jal wait
  j .L_main
  # call reset_game

/* BEGIN:clear_leds */
clear_leds:
  add sp, sp, -4  /*PUSH return adress*/
  sw ra, 0(sp)

  li t1, 0x003FF /*Clear all leds*/
  li t3, LEDS
  sw t1, 0(t3)  /*Put clear led in LEDS register*/
  
  lw ra, 0(sp)  /*POP return adress*/
  add sp, sp, 4
  ret
/* END:clear_leds */

/* BEGIN:set_pixel */
set_pixel:
  add sp, sp, -4  /*PUSH return adress*/
  sw ra, 0(sp)

  li t1, 0        /*Clear register*/
  slli t2, a0, 0    /*Bitshift collumn*/
  or t1, t1, t2
  slli t2, a1, 4    /*Bitshift row*/
  or t1, t1, t2
  li t2, 0x10100
  or t1, t1, t2     /*Select turn on red led*/
  li t2, LEDS
  sw t1, 0(t2)      /*Put t1 in LEDS register*/
  
  lw ra, 0(sp)  /*POP return adress*/
  add sp, sp, 4
  ret
/* END:set_pixel */

/* BEGIN:wait */
wait:
  add sp, sp, -4  /*PUSH return adress*/
  sw ra, 0(sp)

  li t1, 1          /*Load value for */
  slli t1, t1, 19   /*Bitshift to 2^19*/
  li t2, SPEED      /*Load address of SPEED*/
  lb t2, 0(t2)      /*Value to remove each loop*/
  li t4, 10         /*Compare to 10*/
  
  bne t2, t4, .L_wait /*If Game speed is 10, do not wait*/
  ret

.L_wait:
  sub t1, t1, t2    /*Substract loop counter*/
  bge t1, x0, .L_wait /*Go back if not 0*/

  lw ra, 0(sp)  /*POP return adress*/
  add sp, sp, 4
  ret               /*Return after wait is ended*/
/* END:wait */

/* BEGIN:set_gsa */
set_gsa:
  add sp, sp, -4  /*PUSH return adress*/
  sw ra, 0(sp)

  li t1, GSA_ID
  lw t1, 0(t1)    /*Load GSA number used*/

  bne t1, x0, .L_set_gsa_one /*Jump if GSA_ID one*/
  li t2, GSA0     /*Get GSA0 adress*/
  j .L_set_gsa_mul
.L_set_gsa_one:
  li t2, GSA1     /*Get GSA1 adress*/

.L_set_gsa_mul:
  addi t2, t2, 4  /*Calculate GSA line store adress offset*/
  addi a1, a1, -1
  bne a1, x0, .L_set_gsa_mul

  sw a0, 0(t2)   /*Store line at GSA adress offset by line*/

  lw ra, 0(sp)  /*POP return adress*/
  add sp, sp, 4
  ret

/* END:set_gsa */

/* BEGIN:get_gsa */
get_gsa:
  add sp, sp, -4  /*PUSH return adress*/
  sw ra, 0(sp)

  li t1, GSA_ID
  lw t1, 0(t1)    /*Load GSA number used*/

  bne t1, x0, .L_get_gsa_one /*Jump if GSA_ID one*/
  li t2, GSA0     /*Get GSA0 adress*/
  j .L_get_gsa_mul
.L_get_gsa_one:
  li t2, GSA1     /*Get GSA1 adress*/

.L_get_gsa_mul:
  addi t2, t2, 4  /*Calculate GSA line store adress offset*/
  addi a0, a0, -1
  bne a0, x0, .L_get_gsa_mul

  lw a0, 0(t2)   /*Store line at GSA adress offset by line*/

  lw ra, 0(sp)  /*POP return adress*/
  add sp, sp, 4
  ret
/* END:get_gsa */

/* BEGIN:draw_gsa */
draw_gsa:
  add sp, sp, -4  /*PUSH return adress*/
  sw ra, 0(sp)

  lw ra, 0(sp)  /*POP return adress*/
  add sp, sp, 4
  ret
/* END:draw_gsa */

/* BEGIN:random_gsa */
random_gsa:   
  add sp, sp, -4  /*PUSH return adress*/
  sw ra, 0(sp)

  lw ra, 0(sp)  /*POP return adress*/
  add sp, sp, 4
  ret        
/* END:random_gsa */

/* BEGIN:change_speed */
change_speed:
  add sp, sp, -4  /*PUSH return adress*/
  sw ra, 0(sp)

  lw ra, 0(sp)  /*POP return adress*/
  add sp, sp, 4
  ret
/* END:change_speed */

/* BEGIN:pause_game */
pause_game:
  add sp, sp, -4  /*PUSH return adress*/
  sw ra, 0(sp)

  lw ra, 0(sp)  /*POP return adress*/
  add sp, sp, 4
  ret
/* END:pause_game */

/* BEGIN:change_steps */
change_steps:
  add sp, sp, -4  /*PUSH return adress*/
  sw ra, 0(sp)

  lw ra, 0(sp)  /*POP return adress*/
  add sp, sp, 4
  ret
/* END:change_steps */

/* BEGIN:set_seed */
set_seed:
  add sp, sp, -4  /*PUSH return adress*/
  sw ra, 0(sp)

  lw ra, 0(sp)  /*POP return adress*/
  add sp, sp, 4
  ret
/* END:set_seed */

/* BEGIN:increment_seed */
increment_seed:
  add sp, sp, -4  /*PUSH return adress*/
  sw ra, 0(sp)

  lw ra, 0(sp)  /*POP return adress*/
  add sp, sp, 4
  ret               
/* END:increment_seed */

/* BEGIN:update_state */
update_state:
  add sp, sp, -4  /*PUSH return adress*/
  sw ra, 0(sp)

  lw ra, 0(sp)  /*POP return adress*/
  add sp, sp, 4
  ret
/* END:update_state */

/* BEGIN:select_action */
select_action:
  add sp, sp, -4  /*PUSH return adress*/
  sw ra, 0(sp)

  lw ra, 0(sp)  /*POP return adress*/
  add sp, sp, 4
  ret
/* END:select_action */

/* BEGIN:cell_fate */
cell_fate:
  add sp, sp, -4  /*PUSH return adress*/
  sw ra, 0(sp)

  lw ra, 0(sp)  /*POP return adress*/
  add sp, sp, 4
  ret
/* END:cell_fate */

/* BEGIN:find_neighbours */
find_neighbours:
  add sp, sp, -4  /*PUSH return adress*/
  sw ra, 0(sp)

  lw ra, 0(sp)  /*POP return adress*/
  add sp, sp, 4
  ret
/* END:find_neighbours */

/* BEGIN:update_gsa */
update_gsa:
  add sp, sp, -4  /*PUSH return adress*/
  sw ra, 0(sp)

  lw ra, 0(sp)  /*POP return adress*/
  add sp, sp, 4
  ret
/* END:update_gsa */

/* BEGIN:get_input */
get_input:
  add sp, sp, -4  /*PUSH return adress*/
  sw ra, 0(sp)

  lw ra, 0(sp)  /*POP return adress*/
  add sp, sp, 4
  ret
/* END:get_input */

/* BEGIN:decrement_step */
decrement_step:
  add sp, sp, -4  /*PUSH return adress*/
  sw ra, 0(sp)

  lw ra, 0(sp)  /*POP return adress*/
  add sp, sp, 4
  ret
/* END:decrement_step */

/* BEGIN:reset_game */
reset_game:
  add sp, sp, -4  /*PUSH return adress*/
  sw ra, 0(sp)

  lw ra, 0(sp)  /*POP return adress*/
  add sp, sp, 4
  ret
/* END:reset_game */

/* BEGIN:mask */
mask:
  add sp, sp, -4  /*PUSH return adress*/
  sw ra, 0(sp)

  lw ra, 0(sp)  /*POP return adress*/
  add sp, sp, 4
  ret
/* END:mask */

/* 7-segment display */
font_data:
  .word 0x3F
  .word 0x06
  .word 0x5B
  .word 0x4F
  .word 0x66
  .word 0x6D
  .word 0x7D
  .word 0x07
  .word 0x7F
  .word 0x6F
  .word 0x77
  .word 0x7C
  .word 0x39
  .word 0x5E
  .word 0x79
  .word 0x71

  seed0:
	.word 0xC00
	.word 0xC00
	.word 0x000
	.word 0x060
	.word 0x0A0
	.word 0x0C6
	.word 0x006
	.word 0x000
  .word 0x000
  .word 0x000

seed1:
	.word 0x000
	.word 0x000
	.word 0x05C
	.word 0x040
	.word 0x240
	.word 0x200
	.word 0x20E
	.word 0x000
  .word 0x000
  .word 0x000

seed2:
	.word 0x000
	.word 0x010
	.word 0x020
	.word 0x038
	.word 0x000
	.word 0x000
	.word 0x000
	.word 0x000
  .word 0x000
  .word 0x000

seed3:
	.word 0x000
	.word 0x000
	.word 0x090
	.word 0x008
	.word 0x088
	.word 0x078
	.word 0x000
	.word 0x000
  .word 0x000
  .word 0x000


# Predefined seeds
SEEDS:
  .word seed0
  .word seed1
  .word seed2
  .word seed3

mask0:
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
  .word 0xFFF
  .word 0xFFF

mask1:
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0x1FF
	.word 0x1FF
	.word 0x1FF
  .word 0x1FF
  .word 0x1FF

mask2:
	.word 0x7FF
	.word 0x7FF
	.word 0x7FF
	.word 0x7FF
	.word 0x7FF
	.word 0x7FF
	.word 0x7FF
	.word 0x7FF
  .word 0x7FF
  .word 0x7FF

mask3:
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0x000
  .word 0x000
  .word 0x000

mask4:
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0x000
  .word 0x000
  .word 0x000

MASKS:
  .word mask0
  .word mask1
  .word mask2
  .word mask3
  .word mask4
