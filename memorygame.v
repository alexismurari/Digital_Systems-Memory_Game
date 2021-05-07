module pro(SW, KEY, CLOCK_50, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, LEDR, 	
	VGA_CLK,   						
	VGA_HS,							
	VGA_VS,							
	VGA_BLANK_N,						
	VGA_SYNC_N,						
	VGA_R,   						
	VGA_G,	 						
	VGA_B);
	
	output			VGA_CLK;   				
	output			VGA_HS;					
	output			VGA_VS;					
	output			VGA_BLANK_N;				
	output			VGA_SYNC_N;				
	output	[7:0]	VGA_R;   				
	output	[7:0]	VGA_G;	 				
	output	[7:0]	VGA_B;
	
	input [9:0] SW;
	input [3:0] KEY;
	output reg [9:0] LEDR;
	input CLOCK_50;
	output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
	wire [3:0] rand, num, data, disp;
	wire [3:0]num_a, num_b, num_c, num_d, num_e, num_f;
	wire [3:0]round;
	wire [4:0]in;
	wire win, lose;
	wire [3:0] s, d, h;
	wire [2:0] d0, d1, d2, d3, d4, d5, colour;
	wire[8:0]x,y;
	
	randomizer r0(.a(num_a), .b(num_b), .c(num_c), .d(num_d), .e(num_e), .f(num_f), .clk(CLOCK_50), .take_on(~KEY[0]), .number(num));
	num_chosen n0(.num(num), .key(~KEY[3]), .rand(rand));
	num_mem n1(.rand(rand), .a(num_a), .b(num_b), .c(num_c), .d(num_d), .e(num_e), .f(num_f), .win(win), .round(round), .key(KEY[3]), .reset(SW[9]), .sixrounds(SW[6]));
	
	display dh0(.a(num_a), .b(num_b), .c(num_c), .d(num_d), .e(num_e), .f(num_f), .round(round), .hard(SW[8]), .scr(SW[7]), .clk(CLOCK_50), .disp(disp));
	
	fsm u1(.SW(SW[9:0]), .KEY(KEY[3:0]), .win(win), .lose(lose), .a(num_a), .b(num_b), .c(num_c), .d(num_d), .e(num_e), .f(num_f), .round(round));
	
	scoreboard s0(.win(win), .round(round), .lose(lose), .rst(SW[9]), .clk(CLOCK_50), .sec(s), .dsec(d), .hsec(h));

	hexDisplay h0(SW[2:0]+4'b1010, win, round, HEX0);
	hexDisplay h1(round, win, round, HEX1);
	
	hexDisplay h2(disp, win, round, HEX2);
	
	hexDisplay h3(s, 0, 1, HEX3);
	hexDisplay h4(d, 0, 1, HEX4);
	hexDisplay h5(h, 0, 1, HEX5);
	
	
		vga_adapter VGA(
			.resetn(KEY[1]),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(~KEY[0]),
		
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "320x240";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 8;
		defparam VGA.BACKGROUND_IMAGE = "Titlescreen.mif";
	
	
	always @(*)
	begin
			if(round==3'b000 && !SW[6] && win) LEDR=10'b1111111111;
			else if(round==3'b000 && SW[6] && win) LEDR=10'b1111111111;
			else
			begin
				LEDR[9]=win;
				LEDR[8]=win;
				LEDR[7]=win;
				LEDR[0]=lose;
				LEDR[1]=lose;
				LEDR[2]=lose;
				LEDR[6:3]=4'b0000;
			end
	end

endmodule

module randomizer(a, b, c, d, e, f, clk, take_on, number);
	input clk, take_on;
	input [3:0]a, b, c, d, e, f;
	output reg [3:0] number;
	reg [3:0]q;
	
always @(posedge clk)
	begin
	if(q == 4'bx)
		q <=0;
	
	if(q != a && q != b && q != c && q != d && q != e && q != f)
		number <= q;

	q <= q+1;
	
	if(q == 4'b0101)
		q <= 0;

	end
endmodule

module num_mem(rand, a, b, c, d, e, f, win, round, key, reset, sixrounds);
	input win;
	input sixrounds;
	input reset;
	output reg [2:0]round;
	input [3:0]rand;
	output reg[3:0] a, b, c, d, e, f;
	input key;
	
	always@(posedge key)
	begin
		if(round==3'b000)
		begin
			a = 4'b1111;
			b = 4'b1111;
			c = 4'b1111;
			d = 4'b1111;
			e = 4'b1111;
			f = 4'b1111;
			round = 3'b001;
		end
		
		if(win==1) round=round+1;
		
	   else if(round == 3'b001 && a==4'b1111)
			a = rand;
		else if(round == 3'b010 && b==4'b1111)
			b = rand;
		else if(round == 3'b011 && c==4'b1111)
			c = rand;	
		else if(round == 3'b100 && d==4'b1111)
			d = rand;
		else if(round == 3'b101 && e==4'b1111)
			e = rand;
		else if(round == 3'b110 && f==4'b1111)
			f = rand;
		
		if(round == 3'b111 || reset==1 || (round==3'b100 && !sixrounds)) round = 3'b000;	
		
	end

	
endmodule

module num_chosen(num, key, rand);
	input key;
	input [3:0]num;
	output reg[3:0]rand;
	
	always@(posedge key)
	begin
		rand <= num;
	end
endmodule

module fsm(SW, KEY, win, lose, a, b, c, d, e, f, round);
	 input [3:0] a, b, c, d, e , f;
    input [9:0] SW;
    input [3:0] KEY;
	 input [2:0] round;
    output win, lose;
    wire clock, out_light;
    wire [3:0]w;
    wire [2:0]round;
    reg [3:0] y_Q, Y_D; // y_Q represents current state, Y_D represents next state
    localparam A = 4'b0000, B = 4'b0001, C = 4'b0010, D = 4'b0011, E = 4'b0100, F = 4'b0101, G = 4'b0110, H = 4'b0111;
    assign w[2:0] = SW[2:0];
    
    
    assign clock = ~KEY[3];
    //State table
    //The state table should only contain the logic for state transitions
    //Do not mix in any output logic. The output logic should be handled separately.
    //This will make it easier to read, modify and debug the code.
    always@(*)
    begin: state_table
        case (y_Q)
            A: begin //[Round 1]
                        
						if(round==3'b001 && w==a) Y_D = G; //for testing purposes, I have set SW[8] = round 1, SW[7] = round 2, and SW[6] = round 3. Link these later to an X-bit counter for the round number
						else if(w==a) Y_D = B;
						else Y_D = H; //replace the w==4'b0011 to w==x, where x is the randomly generated variable
                
                end
            B: begin //[Round 2]
						if(round==3'b010 && w==b) Y_D = G;
                  else if(w==b) Y_D = C; //replace 4'b0010 for the 2nd variable for round 2
                  else Y_D = H;
                        
               end
            C: begin //[Round 3]
						if(round==3'b011 && w==c) Y_D = G; //added for consistency. In this case, if we were to just have a maximum of 3 rounds then this line then the 'SW[6]' (temp name) requirement is unecessary as both condition lead to case D 
                  else if(w==c) Y_D = D;
                  else Y_D = H;
               end
					
            D: begin //[Round 4]                 
                   if(round==3'b100 && w==d) Y_D = G;
                   else if(w==d) Y_D = E;
                   else Y_D = H;            
               end
            
            E: begin //[Round 5]                 
                   if(round==3'b101 && w==e) Y_D = G;
                   else if(w==e) Y_D = F;
                   else Y_D = H;            
               end
					
				F: begin //[Round 6]                 
                   if(round==3'b110 && w==f) Y_D = G;
                   else if(w==f) Y_D = G;
                   else Y_D = H;            
               end
					
				G: begin //[Win]
                   Y_D = A; //make case D the win condition and reset the FMS back to state A. Increase round number (either here or in a later module)
               end
					
				H: begin //[Round 1 Error]                 
                   if(round==3'b001 && w==a) Y_D = G;
                   else if(w==a) Y_D = B;
                   else Y_D = H;            
               end
				
   
            default: Y_D = A;
        endcase
    end // state_table
    
    // State Registers
    always @(posedge clock)
    begin: state_FFs
        if(round == 3'b000 || SW[9]==1)
            y_Q <=  A; // Should set reset state to state A
        else
            y_Q <= Y_D;
    end // state_FFS
    // Output logic
    // Set out_light to 1 to turn on LED when in relevant states
    assign out_light = ((y_Q == G));
    assign win = out_light;
    assign lose = ((y_Q == H));
    
endmodule

module display(a, b, c, d, e, f, round, hard, scr, clk, disp);
	input [3:0]a, b, c, d, e, f;
	input [2:0]round;
	input clk, hard, scr;
	output reg[3:0]disp;
	reg [25:0]count;
	reg [2:0]print;
	reg [25:0]charizard;
	
	always@(posedge clk)
	begin
			if(hard == 1) charizard = 26'b00011111101011110000011111;
			else charizard = 26'b00111111101011110000011111;
			
			if(scr == 0 && round != 3'b110)
			begin
			
			if(print == 3'b111)	print = 3'b000;
			
			if(print == 3'b000) //A
			begin
				if(4'b0000 != a && 4'b0000 != b && 4'b0000 != c && 4'b0000 != d && 4'b0000 != e && 4'b0000 != f && count == charizard)
				begin
					disp = 4'b1010; //A
					count = 26'b0;
					print = 3'b001;
				end
				else if(count == charizard) 
				begin
				print = 3'b001;
				end
			end
			
			
			if(print == 3'b001) //B
			begin
				if(4'b0001 != a && 4'b0001 != b && 4'b0001 != c && 4'b0001 != d && 4'b0001 != e && 4'b0001 != f && count == charizard) 
				begin
					disp = 4'b1011; //B
					count = 26'b0;
					print = 3'b010;
				end
				else if(count == charizard) 
				begin
				print = 3'b010;
				end
			end
			
			if(print == 3'b010) //C
			begin
				if(4'b0010 != a && 4'b0010 != b && 4'b0010 != c && 4'b0010 != d && 4'b0010 != e && 4'b0010 != f && count == charizard)
				begin
					disp = 4'b1100; //C
					count = 26'b0;
					print = 3'b011;
				end
				else if(count == charizard) 
				begin
				print = 3'b011;
				end
			end
			
			if(print == 3'b011) //D
			begin
				if(4'b0011 != a && 4'b0011 != b && 4'b0011 != c && 4'b0011 != d && 4'b0011 != e && 4'b0011 != f && count == charizard) 
				begin
					disp = 4'b1101; //D
					count = 26'b0;
					print = 3'b100;
				end
				else if(count == charizard) 
				begin
				print = 3'b100;
				end
			end
			
			if(print == 3'b100) //E
			begin
				if(4'b0100 != a && 4'b0100 != b && 4'b0100 != c && 4'b0100 != d && 4'b0100 != e && 4'b0100 != f && count == charizard)
				begin
					disp = 4'b1110; //E
					count = 26'b0;
					print = 3'b101;
				end
				else if(count == charizard) 
				begin
				print = 3'b101;
				end
			end
			
			if(print == 3'b101) //F
			begin
				if(4'b0101!= a && 4'b0101 != b && 4'b0101 != c && 4'b0101 != d && 4'b0101 != e && 4'b0101 != f && count == charizard)
				begin
					disp = 4'b1111; //F
					count = 26'b0;
					print = 3'b111;
				end
				else if(count == charizard) 
				begin
				print = 3'b111;
				count = count - 1;
				end
			end
			
			if(count == charizard) 
			begin
			count = 0;
			print = 3'b000;
			end
			
			count = count+1;
			end
			
			if(scr == 1 && round != 3'b110)
			begin		
			
			if(print == 3'b111)	print = 3'b000;
			
			if(print == 3'b011) //A - 3
			begin
				if(4'b0000 != a && 4'b0000 != b && 4'b0000 != c && 4'b0000 != d && 4'b0000 != e && 4'b0000 != f && count == charizard)
				begin
					disp = 4'b1010; //A
					count = 26'b0;
					print = 3'b100;
				end
				else if(count == charizard) 
				begin
				print = 3'b100;
				count = count - 1;
				end
			end
			
			
			if(print == 3'b000) //B - 0
			begin
				if(4'b0001 != a && 4'b0001 != b && 4'b0001 != c && 4'b0001 != d && 4'b0001 != e && 4'b0001 != f && count == charizard)  
				begin
					disp = 4'b1011; //B
					count = 26'b0;
					print = 3'b001;
				end
				else if(count == charizard) 
				begin
				print = 3'b001;
				count = count - 1;
				end
			end
			
			if(print == 3'b100) //C - 4
			begin
				if(4'b0010 != a && 4'b0010 != b && 4'b0010 != c && 4'b0010 != d && 4'b0010 != e && 4'b0010 != f && count == charizard)
				begin
					disp = 4'b1100; //C
					count = 26'b0;
					print = 3'b101;
				end
				else if(count == charizard) 
				begin
				print = 3'b101;
				count = count - 1;
				end
			end
			
			if(print == 3'b001) //D - 1
			begin
				if(4'b0011 != a && 4'b0011 != b && 4'b0011 != c && 4'b0011 != d && 4'b0011 != e && 4'b0011 != f && count == charizard)  
				begin
					disp = 4'b1101; //D
					count = 26'b0;
					print = 3'b010;
				end
				else if(count == charizard) 
				begin
				print = 3'b010;
				count = count - 1;
				end
			end
			
			if(print == 3'b101) //E - 5
			begin
				if(4'b0100 != a && 4'b0100 != b && 4'b0100 != c && 4'b0100 != d && 4'b0100 != e && 4'b0100 != f && count == charizard)
				begin
					disp = 4'b1110; //E
					count = 26'b0;
					print = 3'b111;
				end
				else if(count == charizard) 
				begin
				print = 3'b111;
				count = count - 1;
				end
			end
			
			if(print == 3'b010) //F - 2
			begin
				if(4'b0101!= a && 4'b0101 != b && 4'b0101 != c && 4'b0101 != d && 4'b0101 != e && 4'b0101 != f && count == charizard)
				begin
					disp = 4'b1111; //F
					count = 26'b0;
					print = 3'b011;
				end
				else if(count == charizard) 
				begin
				print = 3'b011;
				count = count - 1;
				end
			end
			
			if(count == charizard) 
			begin
			count = 0;
			print = 3'b000;
			end
			
			count = count+1;
			
			end
			
			if(round == 3'b110) disp = 4'b0000;
			
	end
endmodule

module scoreboard(win, round, lose, rst, clk, sec, dsec, hsec);
	input clk, rst, win, lose;
	input [2:0]round;
	output reg[4:0]sec, dsec, hsec;
	reg [25:0]count;
	
	always@(posedge clk)
	begin
		if(round == 0 && win == 0)
		begin
			sec = 4'b0;
			dsec = 4'b0;
			hsec = 4'b0;
		end
		
		if(round != 0 && win == 0)
		begin
			if(count == 26'b10011111010111100000111111 && lose == 1)
			begin
			sec = sec + 1;
			end	
			
			if(sec == 4'b1010)
			begin
				dsec = dsec + 1;
				sec = 4'b0;
			end
			if(dsec == 4'b1010)
			begin
				hsec = hsec + 1;
				dsec = 4'b0;
			end
			
			if(count == 26'b10011111010111100000111111)
			begin
			sec = sec + 1;
			count = 0;
			end	
		count = count + 1;
		end
	end
endmodule

module hexDisplay(SW, win, round, HEX0);
	input [3:0] SW;
	input win; 
	input [2:0]round;
	output reg[6:0] HEX0;
	reg c0,c1,c2,c3;
	always @(*)
		begin
			c3=SW[3];
			c2=SW[2];
			c1=SW[1];
			c0=SW[0];
		
			if(round == 3'b110 && c3 == 1'b0 && c2 == 1'b0 && c1 == 1'b0 && c0 == 1'b0)
			begin
				HEX0[0]= 1;
				HEX0[1]= 1;
				HEX0[2]= 1;
				HEX0[3]= 1;
				HEX0[4]= 1;
				HEX0[5]= 1;
				HEX0[6]= 1;
			end
			else if(win || round==3'b000)
			begin
				HEX0[0]= 1;
				HEX0[1]= 1;
				HEX0[2]= 1;
				HEX0[3]= 1;
				HEX0[4]= 1;
				HEX0[5]= 1;
				HEX0[6]= 0;
			end
			else
			begin
				
				HEX0[0]=~((c3|c2|c1|~c0)&(c3|~c2|c1|c0)&(~c3|c2|~c1|~c0)&(~c3|~c2|c1|~c0));
				HEX0[1]=~((c3|~c2|c1|~c0)& (c3|~c2|~c1|c0)&(~c3|c2|~c1|~c0)&(~c3|~c2|c1|c0)&(~c3|~c2|~c1|c0)& (~c3|~c2|~c1|~c0));
				HEX0[2]=~((c3|c2|~c1|c0)&(~c3|~c2|c1|c0)&(~c3|~c2|~c1|c0)&(~c3|~c2|~c1|~c0));
				HEX0[3]=~((c3|c2|c1|~c0)&(c3|~c2|c1|c0)&(c3|~c2|~c1|~c0)&(~c3|c2|~c1|c0)&(~c3|~c2|~c1|~c0)); 
				HEX0[4]=~((c3|c2|c1|~c0)&(c3|c2|~c1|~c0)&(c3|~c2|c1|c0)&(c3|~c2|c1|~c0)&(c3|~c2|~c1|~c0)&(~c3|c2|c1|~c0));
				HEX0[5]=~((c3|c2|c1|~c0)&(c3|c2|~c1|c0)&(c3|c2|~c1|~c0)&(c3|~c2|~c1|~c0)&(~c3|~c2|c1|~c0));
				HEX0[6]=~((c3|c2|c1|c0)&(c3|c2|c1|~c0)&(c3|~c2|~c1|~c0)& (~c3|~c2|c1|c0));
			end
		end
	

endmodule
