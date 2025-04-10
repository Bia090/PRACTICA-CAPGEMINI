module vga_test;
   parameter BP_FIRST =   0;
   parameter HVA =   800;// Horisontal Visible Area
   parameter HFP =   56 ;// Horisontal Front Porch
   parameter HP  =   120;// Horisontal Pulse
   parameter HBP =   64 ;// Horisontal Back Porch
   parameter VVA =   600;// Vertical Visible Area
   parameter VFP =   37 ;// Vertical Front Porch
   parameter VP  =   6  ;// Vertical Pulse
   parameter VBP =   23 ;// Vertical Back Porch
   parameter TP  =   0  ;// Propagation Time


reg clk;
reg rst;
reg en;
wire h_sync;
wire v_sync;
wire red;
wire green;
wire blue;


// Generare ceas
always begin
    #10 clk = ~clk; // ceas 50 MHz
end

// Secvența de testare
initial begin
    // Inițializare intrări
    clk = 0;
    rst = 1;
    en = 0;
    repeat(5) @(posedge clk);

    // Eliberare resetare
    rst = 0;
    repeat(5) @(posedge clk);

    // Activarea controllerului VGA
    en = 1;
    repeat(50000000) @(posedge clk);

    // Dezactivarea controllerului VGA
    en = 0;
    repeat(50000000) @(posedge clk);
    //#100000;
    $display("test");
    // Terminarea simulării
    $stop;
   // $finish;
end

vga_monitor  #(
   .HVA(HVA),  // Horisontal Visible Area
   .HFP(HFP), // Horisontal Front Porch
   .HP (HP ),  // Horisontal Pulse
   .HBP(HBP), // Horisontal Back Porch
   .VVA(VVA),  // Vertical Visible Area
   .VFP(VFP), // Vertical Front Porch
   .VP (VP ), // Vertical Pulse
   .VBP(VBP), // Vertical Back Porch
   .TP (TP ) // Propagation Time
) dut_monitor (
  .clk   (clk   ), // Clock
  .enable(en    ), // Enable
  .reset (rst   ), // Asinchronous reset active high
  .hsync (h_sync ), // Horisontal Sync
  .vsync (v_sync ), // Vertical Sync
  .r     (red     ), // Reg
  .g     (green     ), // Green
  .b     (blue     )  // Blue
);

// Instanțierea controllerului VGA
vga_controller dut (
    .clk(clk),
    .rst(rst),
    .en(en),
    .h_sync(h_sync),
    .v_sync(v_sync),
    .red(red),
    .green(green),
    .blue(blue)
);




 initial begin
$dumpfile("dump.vcd");
$dumpvars(0);
end

endmodule
