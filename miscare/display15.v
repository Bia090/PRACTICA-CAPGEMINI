module display15(                   
    input                     clk            , // 50 MHz
    input                     rst            , // Asynchronous Reset active high
    input                     en             , // enable
    output reg                h_sync         , // Horizontal Synchronization
    output reg                v_sync         , // Vertical Synchronization
    output reg                red            , // Red
    output reg                blue           , // Blue
    output reg                green            // Green
);

parameter H_ACTIVE =  800; // Horizontal Visible area 
parameter H_FP     =   56; // Horizontal Front porch
parameter H_SYNC   =  120; // Horizontal Sync pulse 
parameter H_BP     =   64; // Horizontal Back porch 
parameter H_TOTAL  = 1040; // Horizontal Whole line
parameter V_ACTIVE =  600; // Vertical Visible area
parameter V_FP     =   37; // Vertical Front porch
parameter V_SYNC   =    6; // Vertical Sync pulse
parameter V_BP     =   23; // Vertical Back porch
parameter V_TOTAL  =  666; // Vertical Whole line

// parametru pentru miscare 
parameter MOVE_PERIOD = 500000; // perioada miscarii

// Horizontal and vertical counters
reg [11:0] h_count;
reg [10:0] v_count;

// Counter miscare
reg [25:0] move_count;
reg [9:0]  square_pos1; // pozitie orizontala primul patrat
reg [9:0]  square_pos2; // pozitie orizontala al doilea patrat
reg        direction1;  // directie primul patrat- 0 stanga- 1 dreapta
reg        direction2;  // directie al doilea patrat- 0 stanga- 1 dreapta

// Horizontal Counter 
always @(posedge clk or posedge rst) 
    if (rst)                    h_count <= 0; else 
		if (h_count == H_TOTAL - 1) h_count <= 0; else                        
		                            h_count <= h_count + 1;

always @(posedge clk or posedge rst) 
    if (rst)                    h_sync <= 0;  else 
		if ((h_count >= (H_ACTIVE + H_FP)-1) && (h_count < (H_ACTIVE + H_FP + H_SYNC)-1)) 
                                h_sync <= 0;  else 
																h_sync <= 1;

// Vertical Counter  
always @(posedge clk or posedge rst) 
    if (rst)                    v_count <= 0; else 
		if (v_count == V_TOTAL - 1 && h_count == H_TOTAL - 1) 
																v_count <= 0; else 
    if (h_count == H_TOTAL - 1) v_count <= v_count + 1;

always @(posedge clk or posedge rst) 
    if (rst)                    v_sync <= 0;  else 
		if ((v_count >= (V_ACTIVE + V_FP)-1) && (v_count < (V_ACTIVE + V_FP + V_SYNC)-1)) 
                                v_sync <= 0;  else
                                v_sync <= 1;

// Counter miscare
always @(posedge clk or posedge rst)
    if (rst) begin
        move_count <= 0;
        square_pos1 <= 100; // pozitie initala primul patrat
        square_pos2 <= H_ACTIVE - 200; // pozitie initala al doilea patrat
        direction1 <= 0; // patratul se misca spre dreapta default
        direction2 <= 1; // patratul se misca spre stanga default
    end else if (move_count == MOVE_PERIOD - 1) begin
        move_count <= 0;
        if (direction1 == 0) begin
            if (square_pos1 >= (square_pos2 - 100)) begin
                direction1 <= 1; // schimbare directia spre stanga
            end else begin
                square_pos1 <= square_pos1 + 1;
            end
        end else begin
            if (square_pos1 <= 0) begin
                direction1 <= 0; // schimbare directia spre dreapta
            end else begin
                square_pos1 <= square_pos1 - 1;
            end
        end
        //mutare al doilea patrat
        if (direction2 == 1) begin
            if (square_pos2 <= (square_pos1 + 100)) begin
                direction2 <= 0; // schimbare directia spre dreapta
            end else begin
                square_pos2 <= square_pos2 - 1;
            end
        end else begin
            if (square_pos2 >= (H_ACTIVE - 100)) begin
                direction2 <= 1; // schimbare directia spre stanga
            end else begin
                square_pos2 <= square_pos2 + 1;
            end
        end
    end else begin
        move_count <= move_count + 1;
    end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        red   <= 0;
        green <= 0;
        blue  <= 0;
    end else begin
        if (h_count < H_ACTIVE && v_count < V_ACTIVE && en == 1) begin 
            if (h_count >= square_pos1 && h_count < (square_pos1 + 100) && v_count >= (V_ACTIVE - 350) && v_count < (V_ACTIVE - 250)) begin
                red   <= 0; // turcoaz
                green <= 1;
                blue  <= 1;
            end 
            else if (h_count >= square_pos2 && h_count < (square_pos2 + 100) && v_count >= (V_ACTIVE - 350) && v_count < (V_ACTIVE - 250)) begin
                red   <= 1; // galben
                green <= 1;
                blue  <= 0;
            end 
            else begin
                red   <= 1; // magenta
                green <= 0;
                blue  <= 1;
            end				
        end else begin
            red   <= 0;
            green <= 0;
            blue  <= 0;
        end 
    end
end 
endmodule //display15
