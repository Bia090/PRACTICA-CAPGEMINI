// -----------------------------------------------------------------------------
// Module name: vga monitor
// HDL        : Verilog
// Author     : Nicolae Nicoara (NN)
// Description: The main task of this module is to dump a frame of VGA for 
//              the 800x600 resolution.
// Date       : 22 May, 2023
// -----------------------------------------------------------------------------
// 11/07/2024 (FG) Added back-porch first frame sequence support
//                 Fixed VFP default value

module vga_monitor #(
   parameter BP_FIRST =   0,   // Back porch is sent first
   parameter HVA      =   800, // Horisontal Visible Area
   parameter HFP      =   56, // Horisontal Front Porch
   parameter HP       =   120, // Horisontal Pulse
   parameter HBP      =   64, // Horisontal Back Porch
   parameter VVA      =   600, // Vertical Visible Area
   parameter VFP      =   37, // Vertical Front Porch
   parameter VP       =   6, // Vertical Pulse
   parameter VBP      =   23, // Vertical Back Porch
   parameter TP       =   0 // Propagation Time
) (
  input clk   , // Clock
  input enable, // Enable
  input reset , // Asinchronous reset active high
  input hsync , // Horisontal Sync
  input vsync , // Vertical Sync
  input r     , // Reg
  input g     , // Green
  input b       // Blue
);
// -----------------------------Parameters -------------------------------------
localparam HTOTAL = HVA + HFP + HP + HBP;
localparam VTOTAL = VVA + VFP + VP + VBP;

// -----------------------------Internal Signals -------------------------------
wire        vsync_positive_front_detector;
reg         vsync_delay                  ;
reg  [15:0] cnt_h                        ;
reg  [15:0] cnt_v                        ;
wire        h_visible_area               ;
wire        v_visible_area               ;
wire        visible_area                 ;
integer     fout_pointer                 ;
wire        last_pixel                   ;
wire        last_line                    ;
reg         frame_process                ;
wire        expected_hsync              ;
wire        expected_vsync              ;


// -------------------------------Code -----------------------------------------
initial begin 
  fout_pointer= $fopen("vga_image.bin","wb");
  wait(last_pixel & last_line);
  @(posedge clk);
  @(posedge clk);
  wait(last_pixel & last_line);
  @(posedge clk);
  $fclose(fout_pointer);
  $display("Image is generated ------------------------------------------------------");
  $stop;
end

// Build front detectors for hsync and vsync
always @(posedge clk or posedge reset)
if (reset)  vsync_delay <= #TP 1'd1 ; else
if (enable) vsync_delay <= #TP vsync;

assign vsync_positive_front_detector = (vsync) & (~vsync_delay);

assign last_pixel = cnt_h == (HTOTAL-1);
assign last_line  = cnt_v == (VTOTAL-1);


always @(posedge clk or posedge reset)
if (reset)                                  frame_process <= #TP 1'd0; else
if (~enable)                                frame_process <= #TP 1'd0; else
if (enable & vsync_positive_front_detector) frame_process <= #TP 1'd1;

always @(posedge clk or posedge reset)
if (reset)                                  cnt_h <= #TP 'd0      ; else
if (~enable)                                cnt_h <= #TP 'd0      ; else
if (enable & vsync_positive_front_detector) cnt_h <= #TP 'd1      ; else // Set to 1 because the first pixel (pixel0) was consumed with front detector
if (last_pixel)                             cnt_h <= #TP 'd0      ; else // Reset when line is finished
if (frame_process)                          cnt_h <= #TP cnt_h + 1;      // Increment at each cycle if processing was detected

localparam CNT_V_PRELOAD = BP_FIRST ? 'd0 : VVA + VFP + VP;

always @(posedge clk or posedge reset)
if (reset)                                  cnt_v <= #TP 'd0           ; else
if (~enable)                                cnt_v <= #TP 'd0           ; else
if (enable & vsync_positive_front_detector) cnt_v <= #TP CNT_V_PRELOAD ; else // When front is detected (After VP), set counter to VVA + VFP + VP
if (last_pixel & last_line)                 cnt_v <= #TP 'd0           ; else // Set to 1 because the first pixel (pixel0) was consumed with front detector
if (last_pixel)                             cnt_v <= #TP cnt_v + 1     ;      // Increment at each cycle if processing was detected

assign h_visible_area = BP_FIRST ? cnt_h >= HBP && cnt_h < HBP + HVA : cnt_h < HVA;
assign v_visible_area = BP_FIRST ? cnt_v >= VBP && cnt_v < VBP + VVA : cnt_v < VVA;
assign visible_area   = frame_process & h_visible_area & v_visible_area;


// Check the timing ------------------------------------------------------------
// Hsync and Vsync generators
  assign expected_hsync = BP_FIRST ? ~((cnt_h >= (HBP + HVA + HFP))) : ~((cnt_h >= (HVA + HFP)) & (cnt_h < (HVA + HFP + HP)));
  assign expected_vsync = BP_FIRST ? ~((cnt_v >= (VBP + VVA + VFP))) : ~((cnt_v >= (VVA + VFP)) & (cnt_v < (VVA + VFP + VP)));


always @(posedge clk)
  if (visible_area) begin
     $fwrite(fout_pointer, "%c", {8{b}});
     $fwrite(fout_pointer, "%c", {8{g}});
     $fwrite(fout_pointer, "%c", {8{r}});
  end

always @(posedge clk)
  if (frame_process) begin
     if(expected_hsync ^ hsync)                            begin $display("Wrong Hsync generation")                  ; $stop; end
     if(expected_vsync ^ vsync)                            begin $display("Wrong Vsync generation")                  ; $stop; end
     if(((~h_visible_area) | (~v_visible_area)) & (r|g|b)) begin $display("Color must be 0 outside the visible area"); $stop; end
  end

endmodule
