`timescale 1ns/10ps
typedef struct packed {
  logic RXCn;
  logic TXCn;
  logic UDREn;
  logic FEn;
  logic DORn;
  logic UPEn;
  logic U2Xn;
  logic MPCMn;

} UCSRnA_S;

typedef struct packed {
  logic RXCIEn;
  logic TXCIEn;
  logic UDRIEn;
  logic RXENn;
  logic TXENn;
  logic UCSZn2;
  logic RXB8n;
  logic TXB8n;
} UCSRnB_S;

typedef struct packed {
  logic [1:0] UMSELn;
  logic [1:0] UPMn;
  logic USBSn;
  logic [1:0] UCSZn10;
  logic UCPOLn;
  
} UCSRnC_S;



module u0(u0if interf);
 logic baud_clk;
 logic [11:0] down_counter;
 logic [11:0] UBRRn;
 logic [7:0] ubrrol;
 logic [3:0] ubrroh;
 logic [7:0] UDRn;
 logic [12:0] Tx_shift_reg;
 logic [3:0] cntr;
 logic parity_bit;
 logic shift_reg_flag;
 logic [7:0] RXB;
 logic [2:0] St;
 
 
 UCSRnA_S UA;
 UCSRnB_S UB;
 UCSRnC_S UC;

 assign UBRRn = {ubrroh, ubrrol};

 //assign shift_reg_flag = (Tx_shift_reg == 0) ? 1'b1 : 1'b0;

always@(*)
 begin
  
  if((interf.read == 1'b1) && (interf.addr == 8'hc2))
      begin
       interf.dout[7:6] <= UC.UMSELn;
       interf.dout[5:4] <= UC.UPMn;
       interf.dout[3]<= UC.USBSn;
       interf.dout[2:1] <= UC.UCSZn10;
       interf.dout[0] <= UC.UCPOLn;
      end

    if((interf.read == 1'b1) && (interf.addr == 8'hc1))
      begin
       interf.dout[7] <= UB.RXCIEn;
       interf.dout[6] <= UB.TXCIEn;
       interf.dout[5] <= UB.UDRIEn;
       interf.dout[4] <= UB.RXENn;
       interf.dout[3] <= UB.TXENn;
       interf.dout[2] <= UB.UCSZn2;
       interf.dout[1] <= UB.RXB8n;
       interf.dout[0] <= UB.TXB8n;
      end
     
     if((interf.read == 1'b1) && (interf.addr == 8'hc0))
      begin
       interf.dout[7] <= UA.RXCn;
       interf.dout[6] <= UA.TXCn;
       interf.dout[5] <= UA.UDREn;
       interf.dout[4] <= UA.FEn;
       interf.dout[3] <= UA.DORn;
       interf.dout[2] <= UA.UPEn;
       interf.dout[1] <= UA.U2Xn;
       interf.dout[0] <= UA.MPCMn;
      end
     if((interf.read == 1'b1) &&(interf.addr == 8'hc4))
     interf.dout <= baud_clk;

     if((interf.read == 1'b1) &&(interf.addr == 8'hc5))
     interf.dout <= baud_clk;
     
     if((interf.read == 1'b1) &&(interf.addr == 8'hc6))
     interf.dout <= RXB;    

    end

always@(posedge interf.clk)
 begin
  if((interf.write == 1'b1) && (interf.addr == 8'hc2))
      begin
       UC.UMSELn <= interf.din[7:6];
       UC.UPMn <= interf.din[5:4];
       UC.USBSn <= interf.din[3];
       UC.UCSZn10 <= interf.din[2:1];
       UC.UCPOLn <= interf.din[0];
      end

     if((interf.write == 1'b1) && (interf.addr == 8'hc1))
      begin
       UB.RXCIEn <= interf.din[7];
       UB.TXCIEn <= interf.din[6];
       UB.UDRIEn <= interf.din[5];
       UB.RXENn <= interf.din[4];
       UB.TXENn <= interf.din[3];
       UB.UCSZn2 <= interf.din[2];
       UB.RXB8n <= interf.din[1];
       UB.TXB8n <= interf.din[0];
      end
     
      if((interf.write == 1'b1) && (interf.addr == 8'hc0))
      begin
       UA.RXCn <= interf.din[7];
       UA.TXCn <= interf.din[6];
       UA.UDREn <= interf.din[5];
       UA.FEn <= interf.din[4];
       UA.DORn <= interf.din[3];
       UA.UPEn <= interf.din[2];
       UA.U2Xn <= interf.din[1];
       UA.MPCMn <= interf.din[0];
      end
  end



always@(posedge (interf.clk) or posedge (interf.rst))
 begin
   if(interf.rst) 
    begin
     down_counter <= 12'b0;
     baud_clk <= 1'b0;
     UA <= 8'd32;
     UB <= 8'd0;
     UC <= 8'd6;
     ubrrol <= 8'b0;
     ubrroh <= 4'b0;
     baud_clk <= 1'b0;
     UDRn <= 8'b0;
    end

   else begin
    

     if((interf.write == 1'b1) && (interf.addr == 8'hc4)) 
     ubrrol <= interf.din;

     if((interf.write == 1'b1) && (interf.addr == 8'hc5))
     ubrroh <= interf.din[3:0];
    
     if((UA.UDREn == 1'b1) && ((interf.addr == 8'hc6) && (interf.write == 1'b1)))   // Loading Buffer register and Shift Register
      begin
       UDRn <= interf.din;
       UA.UDREn <= 1'b0;
      end

          
     if(UA.U2Xn == 1'b0)  //Asynchronous Normal Operation
      begin

       if(down_counter == 12'b0) 
        begin
         down_counter <= (8*(UBRRn + 1)) - 1;
         baud_clk <= ~baud_clk;
        end          
         
        else
         down_counter <= down_counter - 1;
        
             
      end
              
     else if(UA.U2Xn == 1'b1)     //Asynchronous Double Speed Operation
      begin
        
        if(down_counter == 12'b0) 
        begin
         down_counter <= (4*(UBRRn + 1)) - 1;
         baud_clk <= ~baud_clk;
        end    
  
       else 
        down_counter <= down_counter - 1;
       
                  
     end

  
     

    end
  end     


always@(posedge (baud_clk) or posedge (interf.rst))
 begin
  if(interf.rst) 
    begin
     //UDRn <= 8'b0;
     cntr = 4'b0;
     parity_bit = 1'b0;
     Tx_shift_reg = 13'b0;
     shift_reg_flag = 1'b1;
     St = 3'b0;
     
    end

   else begin
 
    case(St)
    3'b000: begin
             if((UB.TXENn == 1'b1) && (shift_reg_flag == 1'b1))
              begin
                cntr = 0;
                Tx_shift_reg = 0;
                St = 3'b001;
             end
            else begin
             St = 3'b000;
           end
 
        end
  3'b001: begin

      case({UB.UCSZn2, UC.UCSZn10})
          {1'b1, 2'b11} : begin   // 9 data bits
                           if(UC.USBSn == 1'b0) // Stop bit is 1-bit
                            begin
                             
                             if(UC.UPMn == 2'b10) //Even Parity
                              begin
                               parity_bit = (0 ^ UB.TXB8n ^ UDRn[7] ^ UDRn[6] ^ UDRn[5] ^ UDRn[4] ^ UDRn[3] ^ UDRn[2] ^ UDRn[1] ^ UDRn[0]);
                               if(shift_reg_flag == 1'b1)
                                begin
                                 Tx_shift_reg = {1'b1, parity_bit, UB.TXB8n, UDRn, 1'b0};  // Frame Calculation
                                 UA.UDREn = 1'b1;
                                 cntr = 4'd12;
                                 shift_reg_flag = 1'b0;
                                end  
                               //else 
                                //Tx_shift_reg = Tx_shift_reg;                           
                              end

                             else if(UC.UPMn == 2'b11) // Odd Parity
                              begin  //parity_bit <= (UB.TXB8n ^ (^ UDRn) ^ 1);
                               parity_bit = (1 ^ UB.TXB8n ^ UDRn[7] ^ UDRn[6] ^ UDRn[5] ^ UDRn[4] ^ UDRn[3] ^ UDRn[2] ^ UDRn[1] ^ UDRn[0]);
                               if(shift_reg_flag == 1'b1)
                                begin
                                 Tx_shift_reg = {1'b1, parity_bit, UB.TXB8n, UDRn, 1'b0};  // Frame Calculation
                                 UA.UDREn = 1'b1;
                                 cntr = 4'd12;
                                 shift_reg_flag = 1'b0;
                                end
                               //else 
                                //Tx_shift_reg = Tx_shift_reg;
                              end
 
                             else if(UC.UPMn == 2'b00)  // Parity Disabled
                              begin
                               if(shift_reg_flag == 1'b1)
                                begin
                                 Tx_shift_reg = {1'b1, UB.TXB8n, UDRn, 1'b0};  // Frame Calculation
                                 UA.UDREn = 1'b1;
                                 cntr = 4'd11;
                                 shift_reg_flag = 1'b0;
                                end
                               //else
                                 //Tx_shift_reg = Tx_shift_reg;
                              end 
  
                            end                         
                           else if(UC.USBSn == 1'b1)  // Stop bit is 2-bit 
                            begin

                             if(UC.UPMn == 2'b10) //Even Parity
                              begin
                               parity_bit = (0 ^ UB.TXB8n ^ UDRn[7] ^ UDRn[6] ^ UDRn[5] ^ UDRn[4] ^ UDRn[3] ^ UDRn[2] ^ UDRn[1] ^ UDRn[0]);
                               if(shift_reg_flag == 1'b1)
                                begin
                                 Tx_shift_reg = {1'b1, 1'b1, parity_bit, UB.TXB8n, UDRn, 1'b0};  // Frame Calculation
                                 UA.UDREn = 1'b1;
                                 cntr = 4'd13;
                                 shift_reg_flag = 1'b0;
                                end
                               //else
                                //Tx_shift_reg = Tx_shift_reg;
                              end

                             else if(UC.UPMn == 2'b11) // Odd Parity
                              begin  //parity_bit <= (UB.TXB8n ^ (^ UDRn) ^ 1);
                               parity_bit = (1 ^ UB.TXB8n ^ UDRn[7] ^ UDRn[6] ^ UDRn[5] ^ UDRn[4] ^ UDRn[3] ^ UDRn[2] ^ UDRn[1] ^ UDRn[0]);
                              if(shift_reg_flag == 1'b1)
                               begin
                                 Tx_shift_reg = {1'b1, 1'b1, parity_bit, UB.TXB8n, UDRn, 1'b0};  // Frame Calculation
                                 UA.UDREn = 1'b1;
                                 cntr = 4'd13;
                                 shift_reg_flag = 1'b0;
                                end
                               //else
                                //Tx_shift_reg = Tx_shift_reg;
                              end
 
                             else if(UC.UPMn == 2'b00)  // Parity Disabled
                              begin
                               if(shift_reg_flag == 1'b1)
                                begin
                                 Tx_shift_reg = {1'b1, 1'b1, UB.TXB8n, UDRn, 1'b0};  // Frame Calculation
                                 UA.UDREn = 1'b1;
                                 cntr = 4'd12;
                                 shift_reg_flag = 1'b0;
                                end
                               //else
                                //Tx_shift_reg = Tx_shift_reg;
                              end 
  
                            end    
                         
                                
                          end
          {1'b0, 2'b11} : begin   // For 8 Data bits
                           if(UC.USBSn == 1'b0) // Stop bit is 1-bit
                            begin
                             
                             if(UC.UPMn == 2'b10) //Even Parity
                              begin
                               parity_bit = (0 ^ UDRn[7] ^ UDRn[6] ^ UDRn[5] ^ UDRn[4] ^ UDRn[3] ^ UDRn[2] ^ UDRn[1] ^ UDRn[0]);
                               if(shift_reg_flag == 1'b1)
                                begin
                                 Tx_shift_reg = {1'b1, parity_bit, UDRn, 1'b0};  // Frame Calculation
                                 UA.UDREn = 1'b1;
                                 cntr = 4'd11;
                                 shift_reg_flag = 1'b0;
                                end
                               //else
                               // Tx_shift_reg = Tx_shift_reg;
                              end

                             else if(UC.UPMn == 2'b11) // Odd Parity
                              begin  //parity_bit <= (UB.TXB8n ^ (^ UDRn) ^ 1);
                               parity_bit = (1 ^ UDRn[7] ^ UDRn[6] ^ UDRn[5] ^ UDRn[4] ^ UDRn[3] ^ UDRn[2] ^ UDRn[1] ^ UDRn[0]);
                               if(shift_reg_flag == 1'b1)
                                begin
                                 Tx_shift_reg = {1'b1, parity_bit, UDRn, 1'b0};  // Frame Calculation
                                 UA.UDREn = 1'b1;
                                 cntr = 4'd11;
                                 shift_reg_flag = 1'b0;
                                end
                               //else
                                //Tx_shift_reg = Tx_shift_reg;
                              end
 
                             else if(UC.UPMn == 2'b00)  // Parity Disabled
                              begin 
                               if(shift_reg_flag == 1'b1)
                                begin
                                 Tx_shift_reg = {1'b1, UDRn, 1'b0};  // Frame Calculation
                                 UA.UDREn = 1'b1;
                                 cntr = 4'd10;
                                 shift_reg_flag = 1'b0;
                                end
                               //else
                               // Tx_shift_reg = Tx_shift_reg;
                              end 
  
                            end                         
                           else if(UC.USBSn == 1'b1)  // Stop bit is 2-bit 
                            begin

                             if(UC.UPMn == 2'b10) //Even Parity
                              begin
                               parity_bit = (0 ^ UDRn[7] ^ UDRn[6] ^ UDRn[5] ^ UDRn[4] ^ UDRn[3] ^ UDRn[2] ^ UDRn[1] ^ UDRn[0]);
                               if(shift_reg_flag == 1'b1)
                                begin
                                 Tx_shift_reg = {1'b1, 1'b1, parity_bit, UDRn, 1'b0};  // Frame Calculation
                                 UA.UDREn = 1'b1;
                                 cntr = 4'd12;
                                 shift_reg_flag = 1'b0;
                                end
                               //else
                               // Tx_shift_reg = Tx_shift_reg;
                              end

                             else if(UC.UPMn == 2'b11) // Odd Parity
                              begin  //parity_bit <= (UB.TXB8n ^ (^ UDRn) ^ 1);
                               parity_bit = (1  ^ UDRn[7] ^ UDRn[6] ^ UDRn[5] ^ UDRn[4] ^ UDRn[3] ^ UDRn[2] ^ UDRn[1] ^ UDRn[0]); 
                               if(shift_reg_flag == 1'b1)
                                begin
                                 Tx_shift_reg = {1'b1, 1'b1, parity_bit, UDRn, 1'b0};  // Frame Calculation
                                 UA.UDREn = 1'b1;
                                 cntr = 4'd12;
                                 shift_reg_flag = 1'b0;
                                end
                              // else
                               // Tx_shift_reg = Tx_shift_reg;
                              end
 
                             else if(UC.UPMn == 2'b00)  // Parity Disabled
                              begin
                               if(shift_reg_flag == 1'b1)
                                begin
                                 Tx_shift_reg = {1'b1, 1'b1, UDRn, 1'b0};  // Frame Calculation
                                 UA.UDREn = 1'b1;
                                 cntr = 4'd11;
                                 shift_reg_flag = 1'b0;
                                end
                              // else
                               // Tx_shift_reg = Tx_shift_reg;
                              end 
  
                            end    
                         
                                
                          end
            
        
        {1'b0, 2'b10} : begin   // For 7 data bits
                           if(UC.USBSn == 1'b0) // Stop bit is 1-bit
                            begin
                             
                             if(UC.UPMn == 2'b10) //Even Parity
                              begin
                               parity_bit = (0 ^ UDRn[6] ^ UDRn[5] ^ UDRn[4] ^ UDRn[3] ^ UDRn[2] ^ UDRn[1] ^ UDRn[0]);
                               if(shift_reg_flag == 1'b1)
                                begin
                                 Tx_shift_reg = {1'b1, parity_bit, UDRn[6:0], 1'b0};  // Frame Calculation
                                 UA.UDREn = 1'b1;
                                 cntr = 4'd10;
                                 shift_reg_flag = 1'b0;
                                end
                              // else
                                //Tx_shift_reg = Tx_shift_reg;
                              end

                             else if(UC.UPMn == 2'b11) // Odd Parity
                              begin  //parity_bit <= (UB.TXB8n ^ (^ UDRn) ^ 1);
                               parity_bit = (1 ^ UDRn[6] ^ UDRn[5] ^ UDRn[4] ^ UDRn[3] ^ UDRn[2] ^ UDRn[1] ^ UDRn[0]);
                              if(shift_reg_flag == 1'b1)
                               begin
                                 Tx_shift_reg = {1'b1, parity_bit, UDRn[6:0], 1'b0};  // Frame Calculation
                                 UA.UDREn = 1'b1;
                                 cntr = 4'd10;
                                 shift_reg_flag = 1'b0;
                                end
                              // else
                               // Tx_shift_reg = Tx_shift_reg;
                              end
 
                             else if(UC.UPMn == 2'b00)  // Parity Disabled
                              begin
                               if(shift_reg_flag == 1'b1)
                                begin
                                 Tx_shift_reg = {1'b1, UDRn[6:0], 1'b0};  // Frame Calculation
                                 UA.UDREn = 1'b1;
                                 cntr = 4'd9;
                                 shift_reg_flag = 1'b0;
                                end
                              // else
                               // Tx_shift_reg = Tx_shift_reg;
                              end 
  
                            end                         
                           else if(UC.USBSn == 1'b1)  // Stop bit is 2-bit 
                            begin

                             if(UC.UPMn == 2'b10) //Even Parity
                              begin
                               parity_bit = (0 ^ UDRn[6] ^ UDRn[5] ^ UDRn[4] ^ UDRn[3] ^ UDRn[2] ^ UDRn[1] ^ UDRn[0]);
                               if(shift_reg_flag == 1'b1)
                                begin
                                 Tx_shift_reg = {1'b1, 1'b1, parity_bit, UDRn[6:0], 1'b0};  // Frame Calculation
                                 UA.UDREn = 1'b1;
                                 cntr = 4'd11;
                                 shift_reg_flag = 1'b0;
                                end
                              // else
                               // Tx_shift_reg = Tx_shift_reg;
                              end

                             else if(UC.UPMn == 2'b11) // Odd Parity
                              begin  //parity_bit <= (UB.TXB8n ^ (^ UDRn) ^ 1);
                               parity_bit = (1 ^ UDRn[6] ^ UDRn[5] ^ UDRn[4] ^ UDRn[3] ^ UDRn[2] ^ UDRn[1] ^ UDRn[0]);
                              if(shift_reg_flag == 1'b1)
                               begin
                                 Tx_shift_reg = {1'b1, 1'b1, parity_bit, UDRn[6:0], 1'b0};  // Frame Calculation
                                 UA.UDREn = 1'b1;
                                 cntr = 4'd11;
                                 shift_reg_flag = 1'b0;
                                end
                               //else
                               /// Tx_shift_reg = Tx_shift_reg;
                              end
 
                             else if(UC.UPMn == 2'b00)  // Parity Disabled
                              begin
                               if(shift_reg_flag == 1'b1)
                                begin
                                 Tx_shift_reg = {1'b1, 1'b1, UDRn[6:0], 1'b0};  // Frame Calculation
                                 UA.UDREn = 1'b1;
                                 cntr = 4'd10;
                                 shift_reg_flag = 1'b0;
                                end
                              // else
                              //  Tx_shift_reg = Tx_shift_reg;
                              end 
  
                            end    
                         
                                
                          end
        
        
        {1'b0, 2'b01} : begin   // For 6 data bits
                           if(UC.USBSn == 1'b0) // Stop bit is 1-bit
                            begin
                             
                             if(UC.UPMn == 2'b10) //Even Parity
                              begin
                               parity_bit = (0 ^ UDRn[5] ^ UDRn[4] ^ UDRn[3] ^ UDRn[2] ^ UDRn[1] ^ UDRn[0]);
                               if(shift_reg_flag == 1'b1)
                                begin
                                 Tx_shift_reg = {1'b1, parity_bit, UDRn[5:0], 1'b0};  // Frame Calculation
                                 UA.UDREn = 1'b1;
                                 cntr = 4'd9;
                                 shift_reg_flag = 1'b0;
                                end
                               //else
                               // Tx_shift_reg = Tx_shift_reg;
                              end

                             else if(UC.UPMn == 2'b11) // Odd Parity
                              begin  //parity_bit <= (UB.TXB8n ^ (^ UDRn) ^ 1);
                               parity_bit = (1 ^ UDRn[5] ^ UDRn[4] ^ UDRn[3] ^ UDRn[2] ^ UDRn[1] ^ UDRn[0]);
                               if(shift_reg_flag == 1'b1)
                                begin
                                 Tx_shift_reg = {1'b1, parity_bit, UDRn[5:0], 1'b0};  // Frame Calculation
                                 UA.UDREn = 1'b1;
                                 cntr = 4'd9;
                                 shift_reg_flag = 1'b0;
                                end
                              // else
                               // Tx_shift_reg = Tx_shift_reg;
                              end
 
                             else if(UC.UPMn == 2'b00)  // Parity Disabled
                              begin
                               if(shift_reg_flag == 1'b1)
                                begin
                                 Tx_shift_reg = {1'b1, UDRn[5:0], 1'b0};  // Frame Calculation
                                 UA.UDREn = 1'b1;
                                 cntr = 4'd8;
                                 shift_reg_flag = 1'b0;
                                end
                              // else
                               // Tx_shift_reg = Tx_shift_reg;
                              end 
  
                            end                         
                           else if(UC.USBSn == 1'b1)  // Stop bit is 2-bit 
                            begin

                             if(UC.UPMn == 2'b10) //Even Parity
                              begin
                               parity_bit = (0 ^ UDRn[5] ^ UDRn[4] ^ UDRn[3] ^ UDRn[2] ^ UDRn[1] ^ UDRn[0]);
                               if(shift_reg_flag == 1'b1)
                                begin
                                 Tx_shift_reg = {1'b1, 1'b1, parity_bit, UDRn[5:0], 1'b0};  // Frame Calculation
                                 UA.UDREn = 1'b1;
                                 cntr = 4'd10;
                                 shift_reg_flag = 1'b0;
                                end
                               //else
                               // Tx_shift_reg = Tx_shift_reg;
                              end

                             else if(UC.UPMn == 2'b11) // Odd Parity
                              begin  //parity_bit <= (UB.TXB8n ^ (^ UDRn) ^ 1);
                               parity_bit = (1 ^ UDRn[5] ^ UDRn[4] ^ UDRn[3] ^ UDRn[2] ^ UDRn[1] ^ UDRn[0]);
                               if(shift_reg_flag == 1'b1)
                                begin
                                 Tx_shift_reg = {1'b1, 1'b1, parity_bit, UDRn[5:0], 1'b0};  // Frame Calculation
                                 UA.UDREn = 1'b1;
                                 cntr = 4'd10;
                                 shift_reg_flag = 1'b0;
                                end
                              /// else
                               // Tx_shift_reg = Tx_shift_reg;
                              end
 
                             else if(UC.UPMn == 2'b00)  // Parity Disabled
                              begin
                               if(shift_reg_flag == 1'b1)
                                begin
                                 Tx_shift_reg = {1'b1, 1'b1, UDRn[5:0], 1'b0};  // Frame Calculation
                                 UA.UDREn = 1'b1;
                                 cntr = 4'd9;
                                 shift_reg_flag = 1'b0;
                                end
                              // else
                               // Tx_shift_reg = Tx_shift_reg;
                              end 
  
                            end    
                         
                                
                          end
        
        {1'b0, 2'b00} : begin   // For 5 data bits
                           if(UC.USBSn == 1'b0) // Stop bit is 1-bit
                            begin
                             
                             if(UC.UPMn == 2'b10) //Even Parity
                              begin
                               parity_bit = (0  ^ UDRn[4] ^ UDRn[3] ^ UDRn[2] ^ UDRn[1] ^ UDRn[0]);
                               if(shift_reg_flag == 1'b1)
                                begin
                                 Tx_shift_reg = {1'b1, parity_bit, UDRn[4:0], 1'b0};  // Frame Calculation
                                 UA.UDREn = 1'b1;
                                 cntr = 4'd8;
                                 shift_reg_flag = 1'b0;
                                end
                              // else
                               // Tx_shift_reg = Tx_shift_reg;
                              end

                             else if(UC.UPMn == 2'b11) // Odd Parity
                              begin  //parity_bit <= (UB.TXB8n ^ (^ UDRn) ^ 1);
                               parity_bit = (1 ^ UDRn[4] ^ UDRn[3] ^ UDRn[2] ^ UDRn[1] ^ UDRn[0]);
                               if(shift_reg_flag == 1'b1)
                                begin
                                 Tx_shift_reg = {1'b1, parity_bit, UDRn[4:0], 1'b0};  // Frame Calculation
                                 UA.UDREn = 1'b1;
                                 cntr = 4'd8;
                                 shift_reg_flag = 1'b0;
                                end
                               //else
                               // Tx_shift_reg = Tx_shift_reg;
                              end
 
                             else if(UC.UPMn == 2'b00)  // Parity Disabled
                              begin
                               if(shift_reg_flag == 1'b1)
                                begin
                                 Tx_shift_reg = {1'b1, UDRn[4:0], 1'b0};  // Frame Calculation
                                 UA.UDREn = 1'b1;
                                 cntr = 4'd7;
                                 shift_reg_flag = 1'b0;
                                end
                              // else
                               // Tx_shift_reg = Tx_shift_reg;
                              end 
  
                            end                         
                           else if(UC.USBSn == 1'b1)  // Stop bit is 2-bit 
                            begin

                             if(UC.UPMn == 2'b10) //Even Parity
                              begin
                               parity_bit = (0 ^  UDRn[4] ^ UDRn[3] ^ UDRn[2] ^ UDRn[1] ^ UDRn[0]);
                               if(shift_reg_flag == 1'b1)
                                begin
                                 Tx_shift_reg = {1'b1, 1'b1, parity_bit, UDRn[4:0], 1'b0};  // Frame Calculation
                                 UA.UDREn = 1'b1;
                                 cntr = 4'd9;
                                 shift_reg_flag = 1'b0;
                                end
                              // else
                               // Tx_shift_reg = Tx_shift_reg;
                              end

                             else if(UC.UPMn == 2'b11) // Odd Parity
                              begin  //parity_bit <= (UB.TXB8n ^ (^ UDRn) ^ 1);
                               parity_bit = (1 ^ UDRn[4] ^ UDRn[3] ^ UDRn[2] ^ UDRn[1] ^ UDRn[0]);
                               if(shift_reg_flag == 1'b1)
                                begin
                                 Tx_shift_reg = {1'b1, 1'b1, parity_bit, UDRn[4:0], 1'b0};  // Frame Calculation
                                 UA.UDREn = 1'b1;
                                 cntr = 4'd9;
                                 shift_reg_flag = 1'b0;
                               end
                             // else
                              //  Tx_shift_reg = Tx_shift_reg;
                              end
 
                             else if(UC.UPMn == 2'b00)  // Parity Disabled
                              begin
                               if(shift_reg_flag == 1'b1)
                                begin
                                 Tx_shift_reg = {1'b1, 1'b1, UDRn[4:0], 1'b0};  // Frame Calculation
                                 UA.UDREn = 1'b1;
                                 cntr = 4'd8;
                                 shift_reg_flag = 1'b0;
                                end
                               //else
                                //Tx_shift_reg = Tx_shift_reg;
                              end 
  
                            end    
                         
                                
                          end

  
     endcase 
  St = 3'b010;
 end


   3'b010: begin
        if((UB.TXENn == 1'b1) && ((cntr > 4'b0) && (shift_reg_flag == 1'b0)))
        begin
       interf.txdata = Tx_shift_reg[0];
       Tx_shift_reg = Tx_shift_reg >> 1;
       cntr = cntr - 1;

      if(cntr == 4'b0) begin
      St = 3'b011;
      end
     else begin
     St = 3'b010;
     end
     end

    end
    3'b011: begin
            shift_reg_flag = 1'b1;
            Tx_shift_reg = 0;
            St = 0;
           end
 endcase
end
   end
 //end
 
    
endmodule

