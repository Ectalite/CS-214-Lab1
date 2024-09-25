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
  jal reset_game
  jal get_input
  mv s1, x0             /*Done variable*/
  mv s2, a0             /*e variable*/

.L_main_loop:
  jal select_action
  mv a0, s2             /*Give proper e to update_state*/
  jal update_state
  jal update_gsa
  jal clear_leds
  jal mask
  jal draw_gsa
  jal wait
  jal decrement_step
  mv s1, a0
  jal get_input
  mv s2, a0

  beqz s1, .L_main_loop /*If not done then loop to L_main*/

  j main        /*Infinite loop*/

/* BEGIN:clear_leds */
clear_leds:
  add sp, sp, -4  /*PUSH return adress*/
  sw ra, 0(sp)

  li t1, 0x007FF /*Clear all leds*/
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
  /*slli t1, t1, 19*/   /*Bitshift to 2^19 for real board*/
  slli t1, t1, 10   /*Bitshift to 2^10 for simulation*/
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
  li t1, GSA_ID
  lw t1, 0(t1)    /*Load GSA number used*/

  bne t1, x0, .L_set_gsa_one /*Jump if GSA_ID one*/
  li t2, GSA0     /*Get GSA0 adress*/
  j .L_set_gsa_mul
.L_set_gsa_one:
  li t2, GSA1     /*Get GSA1 adress*/

.L_set_gsa_mul:
  beq a1, x0, .L_set_gsa_l_zero /*Do not add offset if line is 0*/
  addi t2, t2, 4  /*Calculate GSA line store adress offset*/
  addi a1, a1, -1
  blt x0, a1, .L_set_gsa_mul
.L_set_gsa_l_zero:

  sw a0, 0(t2)   /*Store line at GSA adress offset by line*/
  ret

/* END:set_gsa */

/* BEGIN:get_gsa */
get_gsa:
  li t1, GSA_ID
  lw t1, 0(t1)    /*Load GSA number used*/

  bne t1, x0, .L_get_gsa_one /*Jump if GSA_ID one*/
  li t2, GSA0     /*Get GSA0 adress*/
  j .L_get_gsa_mul
.L_get_gsa_one:
  li t2, GSA1     /*Get GSA1 adress*/

.L_get_gsa_mul:
  beq a0, x0, .L_get_gsa_l_zero /*Do not add offset if line is 0*/
  addi t2, t2, 4  /*Calculate GSA line store adress offset*/
  addi a0, a0, -1
  blt x0, a0, .L_get_gsa_mul
.L_get_gsa_l_zero:

  lw a0, 0(t2)   /*Store line at GSA adress offset by line*/
  ret
/* END:get_gsa */

/* BEGIN:draw_gsa */
draw_gsa:
  sw ra, -4(sp)     /*PUSH return adress*/
  sw s1, -8(sp)     /*PUSH s1*/
  sw s2, -12(sp)    /*PUSH s2*/
  sw s3, -16(sp)    /*PUSH s3*/
  add sp, sp, -16   /*Update stack pointer*/

  /*jal clear_leds*/  /*Clear everything*/

  mv s1, x0       /*Line iterator*/
.L_draw_gsa_exloop:
  mv a0, s1
  jal get_gsa
  mv s2, x0       /*Pixel iterator*/
  mv s3, a0       /*Store line value in s3*/
  mv a1, s1       /*Pixel y coordinate is line iterator value*/

.L_draw_gsa_inloop:
  li t1, 1  
  sll t1, t1, s2  /*Used to select bit to show on pixel matrix*/
  and t2, t1, s3  /*Get value of pixel to draw*/

  beq t2, x0, .L_draw_gsa_notOn   /*If pixel is zero, then jump to notOn*/
  mv a0, s2       /*Pixel x coordinate is pixel iterator value*/
  jal set_pixel

.L_draw_gsa_notOn:
  addi s2, s2, 1  /*Increase pixel iterator*/
  li t2, N_GSA_COLUMNS
  bltu s2, t2, .L_draw_gsa_inloop /*Loop if pixel iterator < N_GSA_COLUMNS*/

  addi s1, s1, 1  /*Increase line iterator*/
  li t2, N_GSA_LINES
  bltu s1, t2, .L_draw_gsa_exloop /*Loop if line iterator < N_GSA_LINES*/

  lw s3, 0(sp)    /*POP s3*/
  lw s2, 4(sp)    /*POP s2*/
  lw s1, 8(sp)    /*POP s1*/
  lw ra, 12(sp)   /*POP return address*/
  addi sp, sp, 16
  ret
/* END:draw_gsa */

/* BEGIN:random_gsa */
random_gsa:   
  add sp, sp, -4  /*PUSH return adress*/
  sw ra, 0(sp)
  add sp, sp, -4  /*PUSH s1*/
  sw s1, 0(sp)
  add sp, sp, -4  /*PUSH s2*/
  sw s2, 0(sp)

  mv s1, x0       /*Line iterator*/
.L_random_gsa_exloop:

  mv a0, x0       /*Initialize line to 0*/  
  mv s2, x0       /*Pixel iterator*/
.L_random_gsa_inloop:

  li t1, RANDOM
  lw t1, 0(t1)    /*Get random value*/
  and t1, t1, 2   /*Modulo 2*/
  srli t1, t1, 1  /*Move possible 0x2 to the right*/
  sll t1, t1, s2  /*Move possible 0x1 to the right pixel position*/
  or a0, a0, t1   /*Put pixel value in a0*/

  addi s2, s2, 1                  /*Increase pixel iterator*/
  li t2, N_GSA_COLUMNS
  bltu s2, t2, .L_random_gsa_inloop /*Loop if pixel iterator < N_GSA_COLUMNS*/

  /*Store randomized line*/
  mv a1, s1  /*Give line number*/
  jal set_gsa /*a0 is already set with inloop*/

  addi s1, s1, 1                  /*Increase line iterator*/
  li t2, N_GSA_LINES
  bltu s1, t2, .L_random_gsa_exloop /*Loop if line iterator < N_GSA_LINES*/

  lw s2, 0(sp)  /*POP s2*/
  add sp, sp, 4
  lw s1, 0(sp)  /*POP s1*/
  add sp, sp, 4
  lw ra, 0(sp)  /*POP return adress*/
  add sp, sp, 4
  ret        
/* END:random_gsa */

/* BEGIN:change_speed */
change_speed:
  add sp, sp, -4  /*PUSH return adress*/
  sw ra, 0(sp)

  li t2, SPEED
  lw t3, 0(t2)

  bne a0, x0, .L_change_speed_decrement /*a0 != 0, jump to decrement*/

  li t1, MAX_SPEED
  beq t1, t3, .L_change_speed_end /*If speed is already maximum then end function*/
  addi t3, t3, 1  /*Increment speed*/

  j .L_change_speed_end

.L_change_speed_decrement:
  li t1, MIN_SPEED
  beq t1, t3, .L_change_speed_end /*If speed is already minimum then end function*/
  addi t3, t3, -1 /*Decrement speed*/

.L_change_speed_end:
  sw t3, 0(t2)    /*Save speed*/

  lw ra, 0(sp)  /*POP return adress*/
  add sp, sp, 4
  ret
/* END:change_speed */

/* BEGIN:pause_game */
pause_game:
  add sp, sp, -4  /*PUSH return adress*/
  sw ra, 0(sp)

  li t1, PAUSE
  lw t2, 0(t1)
  xori t2, t2, 1  /*XOR gives us the inverse each time*/
  sw t2, 0(t1)

  lw ra, 0(sp)  /*POP return adress*/
  add sp, sp, 4
  ret
/* END:pause_game */

/* BEGIN:change_steps */
change_steps:
  add sp, sp, -4  /*PUSH return adress*/
  sw ra, 0(sp)

  li t1, CURR_STEP
  lw t2, 0(t1)    /*Load value of current steps*/

  beq a0, x0, .L_change_steps_a0 /*If a0 == 0 then do not increase units*/
  addi t2, t2, 0x001
.L_change_steps_a0:

  beq a1, x0, .L_change_steps_a1 /*If a1 == 0 then do not increase tens*/
  addi t2, t2, 0x010
.L_change_steps_a1:

  beq a2, x0, .L_change_steps_a2 /*If a2 == 0 then do not increase hundreds*/
  addi t2, t2, 0x100
.L_change_steps_a2:

  sw t2, 0(t1)    /*Store value of current steps*/

  lw ra, 0(sp)  /*POP return adress*/
  add sp, sp, 4
  ret
/* END:change_steps */

/* BEGIN:set_seed */
set_seed:
  add sp, sp, -4  /*PUSH return adress*/
  sw ra, 0(sp)
  add sp, sp, -4  /*PUSH s1*/
  sw s1, 0(sp)
  add sp, sp, -4  /*PUSH s2*/
  sw s2, 0(sp)

  li t1, SEED     /*Get current seed id*/
  lw t2, 0(t1)
  lw s1, SEEDS    /*Get SEEDS base adress*/
  beq t2, x0, .L_set_seed_SEEDzero
.L_set_seed_SEEDoffset:
  addi s1, s1, 40
  addi t2, t2, -1
  bne t2, x0, .L_set_seed_SEEDoffset /*Calculate adress offset for the good seed*/
.L_set_seed_SEEDzero:
  mv s2, x0       /*Line iterator*/
.L_set_seed_loop:

  lw a0, 0(s1)    /*Get line from seed*/
  mv a1, s2       /*Give line number*/
  jal set_gsa     /*Store line*/

  addi s1, s1, 4  /*Icrease line address*/
  addi s2, s2, 1  /*Increase line iterator*/
  li t1, N_GSA_LINES
  bltu s2, t1, .L_set_seed_loop /*Loop if line iterator < N_GSA_LINES*/

  lw s2, 0(sp)  /*POP s2*/
  add sp, sp, 4
  lw s1, 0(sp)  /*POP s1*/
  add sp, sp, 4
  lw ra, 0(sp)  /*POP return adress*/
  add sp, sp, 4
  ret
/* END:set_seed */

/* BEGIN:increment_seed */
increment_seed:
  add sp, sp, -4  /*PUSH return adress*/
  sw ra, 0(sp)
  add sp, sp, -4  /*PUSH s1*/
  sw s1, 0(sp)
  add sp, sp, -4  /*PUSH s2*/
  sw s2, 0(sp)

  li t1, CURR_STATE
  lw t1, 0(t1)    /*Get current game state*/
  bne t1, x0, .L_increment_seed_random /*If game state is not INIT then jump to random seed generation*/
  li t1, SEED
  lw t2, 0(t1)    /*Get current seed ID*/
  li t3, N_SEEDS  
  bgeu t2, t3, .L_increment_seed_random /*If seed ID is greater or equal to number of seeds then jump to random seed generation*/

  addi t2, t2, 1
  sw t2, 0(t1)    /*Increase and save seed ID*/

  /*Copy seed in GSA*/
  lw s1, SEEDS    /*Get SEEDS base adress*/
.L_increment_seed_SEEDoffset:
  addi s1, s1, 40
  addi t2, t2, -1
  bne t2, x0, .L_increment_seed_SEEDoffset /*Calculate adress offset for the good seed*/

  mv s2, x0       /*Line iterator*/
.L_increment_seed_loop:

  lw a0, 0(s1)    /*Get line from seed*/
  mv a1, s2       /*Give line number*/
  jal set_gsa     /*Store line*/

  addi s1, s1, 4  /*Icrease line address*/
  addi s2, s2, 1  /*Increase line iterator*/
  li t1, N_GSA_LINES
  bltu s2, t1, .L_increment_seed_loop /*Loop if line iterator < N_GSA_LINES*/
  /*End copy seed in GSA*/
  
  j .L_increment_seed_end
.L_increment_seed_random:

  jal random_gsa

.L_increment_seed_end:

  lw s2, 0(sp)  /*POP s2*/
  add sp, sp, 4
  lw s1, 0(sp)  /*POP s1*/
  add sp, sp, 4
  lw ra, 0(sp)  /*POP return adress*/
  add sp, sp, 4
  ret               
/* END:increment_seed */

/* BEGIN:update_state */
update_state:

  li t3, CURR_STATE 
  
  lw t2, 0(t3)  /*Get current state value*/
  li t1, RUN
  and t1, t1, t2
  bne t1, x0, .L_update_state_endJR /*Quit function if game is running*/

  li t1, RAND
  and t1, t1, t2
  bne t1, x0, .L_update_state_endJC /*Ignore JC if game state is already RAND*/
  
  li t1, JC
  and t2, a0, t1
  beq t2, x0, .L_update_state_endJC /*If JC is not pressed then jump to endJC*/
  li t1, SEED
  lw t1, 0(t1)    /*Load seed ID*/
  li t2, N_SEEDS
  bltu t1, t2, .L_update_state_endJC /*If seed ID < N then jump to endJC*/
  li t1, RAND
  sw t1, 0(t3)  /*Update game state to RAND*/

.L_update_state_endJC:
  li t1, JR
  and t2, a0, t1
  beq t2, x0, .L_update_state_endJR /*If JR is not pressed then jump to endJR*/
  li t1, RUN
  sw t1, 0(t3)  /*Update game state to RUN*/
  li t1, RUNNING
  li t2, PAUSE
  sw t1, 0(t2)  /*Unpause game*/

.L_update_state_endJR:
  ret
/* END:update_state */

/* BEGIN:select_action */
select_action:
  add sp, sp, -4  /*PUSH return adress*/
  sw ra, 0(sp)

  /*s1: buttons pressed*/
  mv s1, a0

  li t1, JC
  and t2, s1, t1
  beq t2, x0, .L_select_action_endJC /*If JC is not pressed then jump to endJC*/
  li t1, CURR_STATE
  lw t1, 0(t1)
  li t2, RUN
  beq t1, t2, .L_select_action_JCpause
  jal increment_seed
  j .L_select_action_endJC
.L_select_action_JCpause:
  li t1, PAUSED
  lw t2, 0(t1)
  xori t2, t2, 0x1
  sw t2, 0(t1)  /*Inverse pause status*/ 

.L_select_action_endJC:

  li t1, JR
  ori t1, t1, JL
  and t2, s1, t1
  beq t2, x0, .L_select_action_endJR_JL /*If JR or JL is not pressed then jump to endJR_JL*/
  li t1, CURR_STATE
  lw t1, 0(t1)
  li t2, RUN
  bne t1, t2, .L_select_action_endJR_JL
  jal change_speed

.L_select_action_endJR_JL:

  li t1, JB
  and t2, s1, t1
  beq t2, x0, .L_select_action_endJB /*If JB is not pressed then jump to endJB*/
  jal reset_game    /*We don't need to return from reset*/

.L_select_action_endJB:

  li t1, JT
  and t2, s1, t1
  beq t2, x0, .L_select_action_endJT /*If JT is not pressed then jump to endJT*/
  li t1, CURR_STATE
  lw t1, 0(t1)
  li t2, RUN
  bne t1, t2, .L_select_action_endJT
  jal random_gsa

.L_select_action_endJT:

  li t1, BUTTON_0
  ori t1, t1, BUTTON_1
  ori t1, t1, BUTTON_2
  and t2, s1, t1
  beq t2, x0, .L_select_action_0_1_2 /*If 0, 1 or 2 is not pressed then jump to 0_1_2*/
  mv t1, s1
  andi a0, t1, BUTTON_0
  andi a1, t1, BUTTON_1
  andi a2, t1, BUTTON_2
  jal change_steps

.L_select_action_0_1_2:

  lw ra, 0(sp)  /*POP return adress*/
  add sp, sp, 4
  ret
/* END:select_action */

/* BEGIN:cell_fate */
cell_fate:
  /*If cell dies or not (a0 number of neighbouring cells and a1 cell state)*/
  mv t2, a0 /*number of neighbouring cells*/

  beq a1, x0, .L_cell_fate_dead /*If cell is dead then jump*/
  li a0, 1
  li t1, 2
  beq t2, t1, .L_cell_fate_end  /*If 2 neighbouring cells then keep alive*/
  li t1, 3
  beq t2, t1, .L_cell_fate_end  /*If 3 neighbouring cells then keep alive*/
  mv a0, x0   /*Else kill cell*/
  j .L_cell_fate_end

.L_cell_fate_dead:
  li t1, 3
  mv a0, a1
  bne t2, t1, .L_cell_fate_end  /*If not 3 neighbouring cells then keep dead*/
  li a0, 1    /*Else reproduction: cell is alive*/

.L_cell_fate_end:
  /*a0 returns cell state (1 alive, 0 dead)*/
  ret
/* END:cell_fate */

/* BEGIN:find_neighbours */
find_neighbours:
  sw ra, -4(sp)     /*PUSH return adress*/
  sw s1, -8(sp)     /*PUSH s1*/
  sw s2, -12(sp)    /*PUSH s2*/
  sw s3, -16(sp)    /*PUSH s3*/
  sw s4, -20(sp)    /*PUSH s4*/
  sw s5, -24(sp)    /*PUSH s5*/
  add sp, sp, -24   /*Update stack pointer*/

  /*a0: cell x coordinate | a1: cell y coordinate*/
  mv s1, x0 /*Neighbours counter*/
  mv s2, a0 /*Cell x coordinate*/
  mv s3, a1 /*Cell y coordinate*/
  /*s4 is x-1 and s5 is x+1*/
  
  /*Calculate x-1 and x+1 mod N_GSA_COLUMNS*/
  addi s4, s2, -1
  bge s4, x0, .L_find_neighbours_C  /*If result of addition is negative, then add N_GSA_COLUMNS*/
  addi s4, s4, N_GSA_COLUMNS
.L_find_neighbours_C:
  addi s5, s2, 1
  li t1, N_GSA_COLUMNS
  blt s5, t1, .L_find_neighbours_D  /*If result of addition bigger/equal than N_GSA_COLUMNS, then add N_GSA_COLUMNS*/
  addi s5, s5, -N_GSA_COLUMNS
.L_find_neighbours_D:

  /*Get line y-1 mod N_GSA_LINES*/
  addi a0, s3, -1
  bge a0, x0, .L_find_neighbours_A  /*If result of addition is negative, then add N_GSA_LINES*/
  addi a0, a0, N_GSA_LINES
.L_find_neighbours_A:
  jal get_gsa   /*Get GSA line*/
  li t1, 1
  srl t2, a0, s4  /*Check x-1*/
  and t2, t2, t1
  add s1, s1, t2
  srl t2, a0, s2  /*Check x*/
  and t2, t2, t1
  add s1, s1, t2
  srl t2, a0, s5  /*Check x+1*/
  and t2, t2, t1
  add s1, s1, t2

  /*Get line y+1 mod N_GSA_LINES*/
  addi a0, s3, 1
  li t1, N_GSA_LINES
  blt a0, t1, .L_find_neighbours_B  /*If result of addition is bigger/equal than N_GSA_LINES, then sub N_GSA_LINES*/
  addi a0, a0, -N_GSA_LINES

.L_find_neighbours_B:
  jal get_gsa     /*Get GSA line*/
  li t1, 1
  srl t2, a0, s4  /*Check x-1*/
  and t2, t2, t1
  add s1, s1, t2
  srl t2, a0, s2  /*Check x*/
  and t2, t2, t1
  add s1, s1, t2
  srl t2, a0, s5  /*Check x+1*/
  and t2, t2, t1
  add s1, s1, t2

  /*Get line y*/
  mv a0, s3
  jal get_gsa     /*Get GSA line*/
  li t1, 1
  srl t2, a0, s4  /*Check x-1*/
  and t2, t2, t1
  add s1, s1, t2
  srl t2, a0, s5  /*Check x+1*/
  and t2, t2, t1
  add s1, s1, t2

  srl a1, a0, s2  /*a1: Cell state (1 alive, 0 dead)*/
  andi a1, a1, 1
  mv a0, s1       /*a0: Count of neighbours*/

  lw s5, 0(sp)    /*POP s5*/
  lw s4, 4(sp)    /*POP s4*/
  lw s3, 8(sp)    /*POP s3*/
  lw s2, 12(sp)   /*POP s2*/
  lw s1, 16(sp)   /*POP s1*/
  lw ra, 20(sp)   /*POP return address*/
  addi sp, sp, 24
  ret
/* END:find_neighbours */

/* BEGIN:update_gsa */
update_gsa:
  sw ra, -4(sp)     /*PUSH return adress*/
  sw s1, -8(sp)     /*PUSH s1*/
  sw s2, -12(sp)    /*PUSH s2*/
  sw s3, -16(sp)    /*PUSH s3*/
  sw s4, -20(sp)    /*PUSH s4*/
  sw s5, -24(sp)    /*PUSH s5*/
  add sp, sp, -24   /*Update stack pointer*/

  li t1, PAUSE
  lw t1, 0(t1)    /*Get game state*/
  li t2, PAUSED
  beq t1, t2, .L_update_gsa_end   /*If game is paused, then end function*/

  /*s2 next GSA addr*/
  /*s3 current x pos*/
  /*s4 current y pos*/
  /*s5 line to store into next GSA*/
  li t1, GSA_ID   /*Get current GSA ID*/
  lw t1, 0(t1)
  beq t1, x0, .L_update_gsa_GETADDRzero  
  li s2, GSA0
  j .L_update_gsa_GETADDRend
.L_update_gsa_GETADDRzero:
  li s2, GSA1
.L_update_gsa_GETADDRend:

  mv s3, x0     /*Line iterator*/
.L_update_gsa_exloop:
  mv s4, x0       /*Pixel iterator*/
  mv s5, x0
.L_update_gsa_inloop:
  mv a1, s3       /*Pixel y coordinate is line iterator value*/
  mv a0, s4
  jal find_neighbours
  jal cell_fate
  sll a0, a0, s4  /*Shift cell state to x position*/
  or s5, s5, a0   /*Save cell state*/

  addi s4, s4, 1  /*Increase pixel iterator*/
  li t2, N_GSA_COLUMNS
  bltu s4, t2, .L_update_gsa_inloop /*Loop if pixel iterator < N_GSA_COLUMNS*/

  /*Store result into next GSA*/
  sw s5, 0(s2)
  addi s2, s2, 4 /*Go to next line in GSA*/

  addi s3, s3, 1  /*Increase line iterator*/
  li t2, N_GSA_LINES
  bltu s3, t2, .L_update_gsa_exloop /*Loop if line iterator < N_GSA_LINES*/

  li t1, GSA_ID   /*Change GSA ID*/
  lw t2, 0(t1)  
  xori t2, t2, 1
  sw t2, 0(t1)

.L_update_gsa_end:
  lw s5, 0(sp)    /*POP s5*/
  lw s4, 4(sp)    /*POP s4*/
  lw s3, 8(sp)    /*POP s3*/
  lw s2, 12(sp)   /*POP s2*/
  lw s1, 16(sp)   /*POP s1*/
  lw ra, 20(sp)   /*POP return address*/
  addi sp, sp, 24
  ret
/* END:update_gsa */

/* BEGIN:get_input */
get_input:
  li t1, BUTTONS
  lw a0, 0(t1)    /*Get buttons status*/
  sw x0, 0(t1)    /*Reset register*/
  ret
/* END:get_input */

/* BEGIN:decrement_step */
decrement_step:
  la t1, CURR_STEP    /*Get current step and isolate each digit*/
  lw t1, 0(t1)

  mv a0, x0         /*Init a0 to 0*/
  li t2, CURR_STATE /*Get current game state*/
  lw t2, 0(t2)
  li t3, RUN
  bne t2, t3, .L_decrement_step_end /*Jump if state is not running*/

  bnez t1, .L_decrement_step_add    /*If step is bigger than zero sub 1*/
  li a0, 1                          /*If step equals zero then return 1*/
  j .L_decrement_step_end

.L_decrement_step_add:
  addi t1, t1, -1
  la t2, CURR_STEP
  sw t1, 0(t2)
.L_decrement_step_end:

  la t0, font_data    /*Get font base address*/
      
  andi t3, t1, 0xF
  slli t3, t3, 2
  add t3, t3, t0
  lw t2, 0(t3)      /*Add first number to seven_segs*/

  srli t3, t1, 4
  andi t3, t3, 0xF
  slli t3, t3, 2
  add t3, t3, t0
  lw t3, 0(t3) 
  slli t3, t3, 8
  or t2, t2, t3     /*Add second number to seven_segs*/

  srli t3, t1, 8
  andi t3, t3, 0xF
  slli t3, t3, 2
  add t3, t3, t0
  lw t3, 0(t3) 
  slli t3, t3, 16
  or t2, t2, t3     /*Add third number to seven_segs*/

  srli t3, t1, 12
  andi t3, t3, 0xF
  slli t3, t3, 2
  add t3, t3, t0
  lw t3, 0(t3) 
  slli t3, t3, 24
  or t2, t2, t3     /*Add forth number to seven_segs*/

  li t3, SEVEN_SEGS /*Store into seven segs register*/
  sw t2, 0(t3)
  ret
/* END:decrement_step */

/* BEGIN:reset_game */
reset_game:
  add sp, sp, -4  /*PUSH return adress*/
  sw ra, 0(sp)

  /*Start with current step to 1*/
  li t1, 1
  li t2, CURR_STEP
  sw t1, 0(t2)

  /*Start with game state to init*/
  li t1, INIT
  li t2, CURR_STATE
  sw t1, 0(t2)

  /*Start with seed to zero*/
  mv t1, x0
  li t2, SEED
  sw t1, 0(t2)

  /*Start with GSA_ID set to zero*/
  li t1, 0
  li t2, GSA_ID
  sw t1, 0(t2)

  /*Start with game paused*/
  li t1, PAUSED
  li t2, PAUSE
  sw t1, 0(t2)

  /*Set game speed*/
  li t1, 1        
  li t2, SPEED
  sw t1, 0(t2)

  /*Make function calls after initializing configuration*/
  jal decrement_step    /*Initialize seven seg*/
  jal set_seed        /*Put seed 0 on screen*/
  jal draw_gsa

  lw ra, 0(sp)  /*POP return adress*/
  add sp, sp, 4
  ret
/* END:reset_game */

/* BEGIN:mask */
mask:
  sw ra, -4(sp)     /*PUSH return adress*/
  sw s1, -8(sp)     /*PUSH s1*/
  sw s2, -12(sp)    /*PUSH s2*/
  sw s3, -16(sp)    /*PUSH s3*/
  add sp, sp, -16   /*Update stack pointer*/

  /*s1: line iterator*/
  /*s2: mask id*/
  /*s3: pixel iterator*/
  lw s2, MASKS  /*Mask ID start address*/
  li t1, SEED
  lw t1, 0(t1)
  beq t1, x0, .L_mask_idEnd
.L_mask_id:
  addi s2, s2, 40 /*Add offset to get good mask ID*/
  addi t1, t1, -1
  bne t1, x0, .L_mask_id
.L_mask_idEnd:

  /*Mask GSA*/
  mv s1, x0     /*Line iterator*/
.L_mask_gsaloop:
  mv a0, s1
  jal get_gsa     /*Load line*/
  lw t1, 0(s2)
  and a0, a0, t1  /*Mask line*/
  mv a1, s1
  jal set_gsa     /*Store line*/

  addi s2, s2, 4  /*Calculate next line mask address*/
  addi s1, s1, 1  /*Increase line iterator*/
  li t1, N_GSA_LINES
  bltu s1, t1, .L_mask_gsaloop /*Loop if line iterator < N_GSA_LINES*/
  
  /*Draw walls*/
  addi s2, s2, -0x28  /*Calculate first line mask address*/
  mv s1, x0     /*Line iterator*/
.L_mask_maskloop:
  mv s3, x0     /*Pixel iterator*/
  lw t3, 0(s2)  /*Load line mask*/
  li t1, 0xFFF 
  xor t3, t3, t1    /*Invert mask*/
  slli t4, t3, 16   /*Set line*/
  slli t3, s1, 4    /*Set row*/
  ori t4, t4, 0xF
  or t4, t4, t3
  li t3, 0x400
  or t4, t4, t3     /*Set blue led*/
  li t2, LEDS
  sw t4, 0(t2)      /*Put t4 in LEDS register*/

  addi s2, s2, 4  /*Calculate next line mask address*/
  addi s1, s1, 1  /*Increase line iterator*/
  li t1, N_GSA_LINES
  bltu s1, t1, .L_mask_maskloop /*Loop if line iterator < N_GSA_LINES*/

  lw s3, 0(sp)    /*POP s3*/
  lw s2, 4(sp)    /*POP s2*/
  lw s1, 8(sp)    /*POP s1*/
  lw ra, 12(sp)   /*POP return address*/
  addi sp, sp, 16
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
