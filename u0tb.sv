//
// A test bench for the USART0 design
//
`timescale 1ns/10ps

`include "u0if.sv"
`include "u0.sv"

package u0_pkg;

`include "uvm.sv"

import uvm_pkg::*;

//
//
//
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
//
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
//
typedef struct packed {
  logic [1:0] UMSELn;
  logic [1:0] UPMn;
  logic USBSn;
  logic [1:0] UCSZn10;
  logic UCPOLn;
  
} UCSRnC_S;

class mjerr;
  static task err(string loc, string msg);
    begin
      `uvm_error(loc,msg)
      $finish;
    end
  endtask : err

endclass : mjerr

class ctl_item ;
  UCSRnA_S a;
  UCSRnB_S b;
  UCSRnC_S c;
  logic [11:0] bdiv;
  integer csize;
endclass : ctl_item


class rx_chunk;
  UCSRnA_S uA;
  UCSRnB_S uB;
  logic [7:0] uD;
  
  function string toStr();
    return $sformatf("CSRA %02h CSRB %02h DR %h",uA,uB,uD);
  endfunction : toStr

endclass : rx_chunk;
//
//

class tx_item ;
  logic txd;
  logic txen;
  logic txtc,tcack;
  logic txir,txack;
  logic rxir,rxack;
  realtime tstamp;
  function new(logic td,logic ten);
    tstamp = $realtime;
    txd=td;
    txen=ten;
  endfunction : new
endclass : tx_item

class rwrite_item ;
  realtime tstamp;
  logic [7:0] addr,wdata;
  function new(logic [7:0] xaddr,logic[7:0] xwdata);
    tstamp = $realtime;
    addr = xaddr;
    wdata = xwdata;
  endfunction : new

endclass : rwrite_item
//
//
//
class rx_si extends uvm_sequence_item;

  rand logic [8:0] rxd;
  int wait_clks;
  logic [2:0] rxe;
  `uvm_object_utils(rx_si) 
  
  function new(string name = "rx");
    super.new(name);
  endfunction

function void do_copy(uvm_object rhs);
 begin
  rx_si rhs_;

  if(!$cast(rhs_, rhs)) begin
    uvm_report_error("do_copy", "cast failed, check types");
  end
  rxd = rhs_.rxd;
  wait_clks = rhs_.wait_clks;
  rxe = rhs_.rxe;
 end
endfunction: do_copy

function bit do_compare(uvm_object rhs, uvm_comparer comparer);
 begin
  rx_si rhs_;

  do_compare = $cast(rhs_, rhs) &&
               super.do_compare(rhs, comparer) &&
               rxd == rhs_.rxd &&
               wait_clks == rhs_.wait_clks ;
 end
endfunction: do_compare

function string toStr();
  return $sformatf("rxd(%h) wait(%d) err(%h)",
    rxd,wait_clks,rxe);
endfunction: toStr

function void do_print(uvm_printer printer);

  if(printer.knobs.sprint == 0) begin
    $display(toStr());
  end
  else begin
    printer.m_string = toStr();
  end

endfunction: do_print

function void do_record(uvm_recorder recorder);
 begin
  super.do_record(recorder);

  `uvm_record_field("rxd", rxd);
  `uvm_record_field("wait_clks", wait_clks);
 end
endfunction: do_record

endclass : rx_si

//
//
//

class u0_si extends uvm_sequence_item;

logic read,write; // read and write signals
logic rst;	// reset signal
logic wait_tx;	// wait for the transmitter to take data.
logic [7:0] addr; // address
logic [7:0] din;  // data to dut
logic [7:0] dout; // data from dut

typedef enum logic [7:0] { UCSR0A=8'hc0,UCSR0B,UCSR0C,UBRR0L=8'hc4,UBRR0H,UDR0=8'hc6
    } uA;
typedef enum int { ucsr0a,ucsr0b,ucsr0c,ubrr0l,ubbr0h,udr0 } ua;

static int amap[0:5]='{UCSR0A,UCSR0B,UCSR0C,UBRR0L,UBRR0H,UDR0};
  
`uvm_object_utils_begin(u0_si)
  `uvm_field_int(read,UVM_ALL_ON)
  `uvm_field_int(write,UVM_ALL_ON)
  `uvm_field_int(rst,UVM_ALL_ON)
  `uvm_field_int(addr,UVM_ALL_ON)
  `uvm_field_int(din,UVM_ALL_ON)
  `uvm_field_int(dout,UVM_ALL_ON)
`uvm_object_utils_end

function new(string name = "si");
  super.new(name);
endfunction

function void do_copy(uvm_object rhs);
 begin
  u0_si rhs_;

  if(!$cast(rhs_, rhs)) begin
    uvm_report_error("do_copy", "cast failed, check types");
  end
  read = rhs_.read;
  rst = rhs_.rst;
  write = rhs_.write;
  addr = rhs_.addr;
  din = rhs_.din;
  dout = rhs_.dout;
 end
endfunction: do_copy

function bit do_compare(uvm_object rhs, uvm_comparer comparer);
 begin
  u0_si rhs_;

  do_compare = $cast(rhs_, rhs) &&
               super.do_compare(rhs, comparer) &&
               read == rhs_.read &&
               write == rhs_.write &&
               addr == rhs_.addr &&
               din == rhs_.din &&
               rst == rhs_.rst &&
               dout == rhs_.dout ;
 end
endfunction: do_compare

function string toStr();
  return $sformatf("rst(%d) w(%d) r(%d) addr(%h) din(%h) dout(%h)",
    rst,write,read,addr,din,dout);
endfunction: toStr

function void do_print(uvm_printer printer);

  if(printer.knobs.sprint == 0) begin
    $display(toStr());
  end
  else begin
    printer.m_string = toStr();
  end

endfunction: do_print

function void do_record(uvm_recorder recorder);
 begin
  super.do_record(recorder);

  `uvm_record_field("read", read);
  `uvm_record_field("write", write);
  `uvm_record_field("addr", addr);
  `uvm_record_field("din",din);
  `uvm_record_field("dout",dout);
 end
endfunction: do_record

endclass: u0_si

//
// clears the tcir interrupt flag after a random wait
//
`uvm_analysis_imp_decl(_bit)
`uvm_analysis_imp_decl(_cper)
`uvm_analysis_imp_decl(_bdiv)
`uvm_analysis_imp_decl(_csize)
`uvm_analysis_imp_decl(_ctl)
`uvm_analysis_imp_decl(_cperiod)



class sbtcir extends uvm_scoreboard;
  `uvm_component_utils(sbtcir)
  
  uvm_analysis_imp_bit #(bit,sbtcir) xmit_complete;
  uvm_analysis_imp_cper #(realtime,sbtcir) cper;
  uvm_analysis_imp #(bit,sbtcir) enable_ir_response;
  uvm_analysis_imp_ctl #(ctl_item,sbtcir) ctlMsg;
  
  realtime complete_time;
  realtime rupt_time;
  realtime cperiod;
  ctl_item ci;
  
  bit ir_enable;

  function new(string name="sbtcir",uvm_component par=null);
    super.new(name,par);
    cperiod=1e-9;
  endfunction : new
  
  function void build_phase(uvm_phase phase);
    xmit_complete = new("xmit_complete",this);
    cper = new("cper",this);
    enable_ir_response=new("enable_ir_resp",this);
    ctlMsg = new("ctlMsg",this);
  endfunction : build_phase
  
  function void write_ctl(ctl_item itm);
    ci = itm;
  endfunction : write_ctl

  function void write(bit b);
    ir_enable = b;
  endfunction : write
  
  function void write_bit(bit b);
    complete_time = $realtime;
//    `uvm_info("debug",$sformatf("xmit complete at %7.0f",complete_time),UVM_LOW)
  endfunction : write_bit
  
  function void write_cper(realtime cp);
    cperiod = cp;
  endfunction : write_cper


endclass : sbtcir

class tcirmon extends uvm_monitor;
  `uvm_component_utils(tcirmon)
  uvm_analysis_port #(realtime) ir_rupt;
  
  virtual u0if if0;
  
  logic oldval;
  
  function new(string name="tcirmon",uvm_component par=null);
    super.new(name,par);
  endfunction : new
  
  function void build_phase(uvm_phase phase);
    ir_rupt = new("ir_rupt",this);
  endfunction : build_phase
  
  function void connect_phase(uvm_phase phase);
      if (!uvm_config_db #(virtual u0if)::get(null, "uvm_test_top",
          "u0_if", this.if0)) begin
          mjerr::err("connect", "u0_if not found");
      end 
  endfunction: connect_phase;

  
  task run_phase(uvm_phase phase);
   begin
    fork
      forever begin
        @(if0.CB);
        if(if0.rst==0) begin
          if(if0.tcir && oldval==0) begin            
            ir_rupt.write($realtime);
            repeat($urandom_range(4,20)) @(if0.CB);
            #1 if0.tcack=1;
            @(if0.CB);
            #1 if0.tcack=0;
            @(if0.CB);
          end
        end
        oldval = if0.tcir;
      end
    join_none
   end
  endtask : run_phase


endclass : tcirmon


class txirmon extends uvm_monitor;
  `uvm_component_utils(txirmon)
  uvm_analysis_port #(realtime) tx_rupt;
  
  virtual u0if if0;
  
  logic oldval;
  
  function new(string name="txirmon",uvm_component par=null);
    super.new(name,par);
  endfunction : new
  
  function void build_phase(uvm_phase phase);
    tx_rupt = new("tx_rupt",this);
  endfunction : build_phase
  
  function void connect_phase(uvm_phase phase);
      if (!uvm_config_db #(virtual u0if)::get(null, "uvm_test_top",
          "u0_if", this.if0)) begin
          mjerr::err("connect", "u0_if not found");
      end 
  endfunction: connect_phase;

  
  task run_phase(uvm_phase phase);
   begin
    fork
      forever begin
        @(if0.CB);
        if(if0.rst==0) begin
          if(if0.txir==1 && oldval==0) begin            
            tx_rupt.write($realtime);
          end else if(if0.txir==1) begin
            repeat($urandom_range(40,200)) @(if0.CB);
            #1 if0.txack=1;
            @(if0.CB);
            #1 if0.txack=0;
            @(if0.CB);
          end
        end
        oldval = if0.txir;
      end
    join_none
   end
  endtask : run_phase


endclass : txirmon

class rxirmon extends uvm_monitor;
  `uvm_component_utils(rxirmon)
  uvm_analysis_port #(realtime) rx_rupt;
  
  virtual u0if if0;
  
  logic oldval;
  
  function new(string name="rxirmon",uvm_component par=null);
    super.new(name,par);
  endfunction : new
  
  function void build_phase(uvm_phase phase);
    rx_rupt = new("rx_rupt",this);
  endfunction : build_phase
  
  function void connect_phase(uvm_phase phase);
      if (!uvm_config_db #(virtual u0if)::get(null, "uvm_test_top",
          "u0_if", this.if0)) begin
          mjerr::err("connect", "u0_if not found");
      end 
  endfunction: connect_phase;

  
  task run_phase(uvm_phase phase);
   begin
    fork
      forever begin
        @(if0.CB);
        if(if0.rst==0) begin
          if(if0.rxir==1 && oldval==0) begin            
            rx_rupt.write($realtime);
            repeat($urandom_range(40,200)) @(if0.CB);
            #1 if0.rxack=1;
            @(if0.CB);
            #1 if0.rxack=0;
            @(if0.CB);
          end
        end
        oldval = if0.rxir;
      end
    join_none
   end
  endtask : run_phase


endclass : rxirmon


//
//
//
`uvm_analysis_imp_decl(_citx)

class txmon extends uvm_monitor;
  `uvm_component_utils(txmon)
  uvm_analysis_port #(tx_item) txi;
  uvm_analysis_port #(rwrite_item) wri;
  uvm_analysis_imp #(logic [1:0],txmon) txenMsg;
  uvm_analysis_imp_citx #(ctl_item,txmon) ctlMsg;
  
  virtual u0if if0;

  tx_item ti;
  rwrite_item wi;
  logic txen;
  ctl_item ci;

  function new(string name="txmon",uvm_component par=null);
    super.new(name,par);
  endfunction : new
  
  function void build_phase(uvm_phase phase);
    txi = new("txap",this);
    wri = new("wri",this);
    txenMsg = new("txenMsg",this);
    ctlMsg = new("ctlMsg",this);
  endfunction : build_phase
  
  function void connect_phase(uvm_phase phase);
      if (!uvm_config_db #(virtual u0if)::get(null, "uvm_test_top",
        "u0_if", this.if0)) begin
          mjerr::err("connect", "u0_if not found");
         end 
  endfunction: connect_phase;
  
  function void write_citx(ctl_item cx);
    if(cx == null) begin
      `uvm_info("debug","Got a null citem",UVM_LOW)
    end
    ci=cx;
  endfunction : write_citx
  
  function void write(logic [1:0] rxtx);
    txen = rxtx[0];
  endfunction : write

  task run_phase(uvm_phase phase);
    begin
      fork
        forever begin
          @(if0.CB);
          if(if0.rst==0) begin
            ti=new(if0.txdata,txen);
            ti.txir=if0.txir;
            ti.tcack=if0.tcack;
            ti.txir=if0.txir;
            ti.txack=if0.txack;
            ti.rxir=if0.rxir;
            ti.rxack=if0.rxack;
            if(ci != null && ci.b.TXENn) txi.write(ti);
            if(if0.write==1) begin
              wi = new(if0.addr,if0.din);
              wri.write(wi);
            end
          end
        end
      join_none
    end
  endtask : run_phase

endclass : txmon
//
//
//


//
//
//

class rgsb0 extends uvm_scoreboard;
  `uvm_component_utils(rgsb0)
  
  uvm_tlm_analysis_fifo #(rwrite_item) wfifo;
  uvm_analysis_port #(logic [11:0]) baudMsg;
  uvm_analysis_port #(logic [8:0]) wdataMsg;
  uvm_analysis_port #(int) csizeMsg;
  uvm_analysis_port #(ctl_item) ctlMsg;
  uvm_analysis_port #(logic [1:0]) rxtxen;
  
  rwrite_item wi;
  logic [11:0] bdiv;
  
  ctl_item ci;

  int UCSZn;


  function new(string name="rgsb0",uvm_component par=null);
    super.new(name,par);
  endfunction : new
  
  function void build_phase(uvm_phase phase);
    wfifo = new("wfifo",this);
    baudMsg = new("baudMsg",this);
    wdataMsg = new("wdataMsg",this);
    csizeMsg = new("csizeMsgO",this);
    ctlMsg = new("ctlMsg",this);
    rxtxen = new("rxenMsg",this);
    ci = new();
    
  endfunction : build_phase
  
  task sendbaudrate();
    begin
      baudMsg.write(bdiv);
      ctlMsg.write(ci);
//      `uvm_info("baudRate",$sformatf("baudrate %h (%d)",bdiv,bdiv),UVM_LOW)
    end
  endtask : sendbaudrate
  
  task sendwdata(input logic [8:0] wdat);
    begin
      wdataMsg.write(wdat);
//      `uvm_info("debug","send wdata to fifo",UVM_LOW)
    end
  endtask : sendwdata;
  
  task aChanged;
    ctlMsg.write(ci);
  endtask : aChanged
  
  task bChanged;
    begin
      UCSZn = (ci.b.UCSZn2)?9:(ci.c.UCSZn10+5) ;
      csizeMsg.write(UCSZn);
      ci.csize=UCSZn;
      ctlMsg.write(ci);
      rxtxen.write( {ci.b.RXENn,ci.b.TXENn} );
    end
  endtask : bChanged
  
  task cChanged;
    begin
      UCSZn = (ci.b.UCSZn2)?9:(ci.c.UCSZn10+5) ;
      csizeMsg.write(UCSZn);
      ci.csize = UCSZn;
      ctlMsg.write(ci);
    end
  endtask : cChanged
  
  task run_phase(uvm_phase phase);
    fork
      forever begin
        wfifo.get(wi);
///        `uvm_info("debug","checking a write",UVM_LOW)
        case(wi.addr)
          u0_si::UBRR0L:
            begin
              bdiv = {bdiv[11:8],wi.wdata};
              ci.bdiv=bdiv;
              sendbaudrate;
            end
          u0_si::UBRR0H:
            begin
              bdiv = {wi.wdata[3:0],bdiv[7:0]};
              ci.bdiv=bdiv;
              sendbaudrate;
            end
          u0_si::UCSR0A:
            begin
              ci.a = wi.wdata;
              aChanged;
            end
          u0_si::UCSR0B:
            begin
              ci.b = wi.wdata;
              bChanged;
            end
          u0_si::UCSR0C:
            begin
              ci.c = wi.wdata;
              cChanged;
            end
          u0_si::UDR0:
            begin
              if(ci.b.TXENn) sendwdata(wi.wdata);
            end
          default:
            `uvm_info("unhandled",$sformatf("unhandled write of %h",wi.addr),UVM_LOW)
        endcase
      end
    join_none
  endtask : run_phase
endclass : rgsb0
//
//
//



class irsb extends uvm_scoreboard;
  `uvm_component_utils(irsb)
  uvm_analysis_imp_ctl #(ctl_item,irsb) ctlMsg;
  uvm_tlm_analysis_fifo #(tx_item) tf;
  
  ctl_item ci;
  tx_item ti;
  
  function new(string name="irsb",uvm_component par);
    super.new(name,par);
  endfunction : new
  
  function void build_phase(uvm_phase phase);
    ctlMsg = new("cim",this);
    tf = new("txfifo",this);
  endfunction : build_phase

  function void connect_phase(uvm_phase phase);
  
  endfunction : connect_phase
  
  function void write_ctl(ctl_item citm);
    ci = citm;
  endfunction : write_ctl
  
  task run_phase(uvm_phase phase);
    fork
      forever begin
        tf.get(ti);
        
      end
    join_none
  endtask : run_phase

endclass : irsb

//
//
//
class txsbtm extends uvm_scoreboard;
  `uvm_component_utils(txsbtm)
  uvm_tlm_analysis_fifo #(tx_item) tf;
  uvm_analysis_imp_bdiv #(logic [11:0],txsbtm) bdivMsg;
  uvm_analysis_imp_ctl #(ctl_item,txsbtm) ctlMsg;
  uvm_analysis_imp_cperiod #(realtime,txsbtm) cperiodMsg;

  typedef enum { Sidle,Stiming } State;
  
  int bdiv;
  tx_item ti;
  ctl_item ci;
  realtime clk_period;
  realtime last_time,this_time,delta_time,expected_time;
  realtime error_amount;
  logic oldval;
  State cs;
  int ix;
  bit multseen;
  
  function new(string name="txsbtm",uvm_component par=null);
    super.new(name,par);
    last_time=0;
    this_time=0;
    clk_period = 1.0;
    oldval=0;
    cs=Sidle;
  endfunction : new
  
  function void write_bdiv(logic [11:0] bi);
    bdiv = bi;
  endfunction : write_bdiv
  
  function void write_cperiod(realtime iv);
    clk_period = iv;
  endfunction : write_cperiod
 
  function void write_ctl(ctl_item citm);
    begin
      ci = citm;
//      `uvm_info("debug","got a ctl_item",UVM_LOW);
    end
  endfunction : write_ctl
  
  function void build_phase(uvm_phase phase);
    tf = new("tf",this);
    bdivMsg = new("bdivMsg",this);
    ctlMsg = new("ctlMsg",this);
    cperiodMsg = new("clk_period",this);
  endfunction : build_phase
  
  task run_phase(uvm_phase phase);
    fork
      forever begin
        tf.get(ti);
        case(cs)
          Sidle: begin
            if(ti.txd==0 && oldval==1) begin
              last_time = ti.tstamp;
              cs = Stiming;
            end
          end
          Stiming: begin
            if(ti.txd != oldval) begin // an edge
              this_time = ti.tstamp;
              delta_time=this_time-last_time;
              expected_time = (bdiv+1)*clk_period*8.0*((ci.a.U2Xn)?1.0:2.0);
              multseen=0;
              for(ix=1; ix < 13; ix=ix+1) begin
                error_amount = delta_time-expected_time*ix;
                if(error_amount < 0.0) error_amount = -error_amount;
                if( error_amount <0.01) multseen=1;
              end
              if(multseen==0) begin
                `uvm_info("debug",$sformatf("delta time %7.0f expected %7.0f mult %7.2f",delta_time,expected_time,delta_time/expected_time),UVM_LOW)
              end
              cs=Sidle; // look for next drop
            end
          end
        endcase
        oldval = ti.txd;
      end
    join_none
  endtask : run_phase

endclass : txsbtm

//
//
//
class clksb extends uvm_scoreboard;
  `uvm_component_utils(clksb)
  uvm_analysis_imp #(tx_item,clksb) txi;
  uvm_analysis_port #(realtime) mcperiod;
  
  realtime lasttime;
  realtime clkperiod,newclkperiod;
  
  function new(string name="clksb",uvm_component par=null);
    super.new(name,par);
    lasttime=0.0;
    clkperiod=0.0;
    newclkperiod=0.0;
  endfunction : new
  
  function void build_phase(uvm_phase phase);
    txi = new("clk_txi",this); 
    mcperiod = new("clk_period",this);
  endfunction : build_phase
  
  function void write(tx_item ti);
    begin
     newclkperiod = ti.tstamp-lasttime;
     if(newclkperiod != clkperiod) begin
//       `uvm_info("debug",$sformatf("clk period now %7.0f tt %e lt %e",newclkperiod,ti.tstamp,lasttime),UVM_LOW)
       clkperiod = newclkperiod;
       mcperiod.write(clkperiod);
     end
     lasttime = ti.tstamp;
    end
  endfunction : write
  
endclass : clksb


class txsb0 extends uvm_scoreboard;
  `uvm_component_utils(txsb0)

  uvm_tlm_analysis_fifo #(tx_item) tf;
  uvm_analysis_imp_bdiv #(logic [11:0],txsb0) bdivMsg;
  uvm_analysis_imp_csize #(int,txsb0) csizeMsg;
  uvm_tlm_analysis_fifo #(logic [8:0]) wdataFifo;
  uvm_analysis_imp_ctl #(ctl_item,txsb0) ctlMsg;
  uvm_analysis_port #(bit) xmit_complete;
  
  tx_item ti;
  int syncnt;
  int bdiv;
  int txbpos;
  int csize;
  logic [8:0] received;
  logic [8:0] expected;
  logic received_parity,expected_parity;
  ctl_item ci;
  
  
  typedef enum { txIdle,txsync,txdata,txparity,
        txstop0,txstop1,txstop2,txHang} txStates;
  txStates cs;

  function new(string name="txsb0",uvm_component par=null);
    super.new(name,par);
    cs = txIdle;
  endfunction : new
  
  function void write_bdiv(logic [11:0] bi);
    bdiv = bi;
  endfunction : write_bdiv
  
  function void write_csize(int cs);
    begin
    csize=cs;
//    `uvm_info("debug",$sformatf("Setting csize %d",cs),UVM_LOW)
    end
  endfunction : write_csize
  
  function void write_ctl(ctl_item citm);
    begin
      ci = citm;
    end
  endfunction : write_ctl
  
  function void build_phase(uvm_phase phase);
    tf = new("tf",this);
    bdivMsg = new("bdivMsg",this);
    wdataFifo = new("wdataFifo",this);
    csizeMsg = new("csizeMsg",this);
    ctlMsg = new("ctlMsg",this);
    xmit_complete = new("xmit_complete",this);
  endfunction : build_phase
  
  function int halfBit();
    return (bdiv+1)*4*((ci.a.U2Xn)?1:2);
  endfunction : halfBit
  
  function int fullBit();
    return (bdiv+1)*8*((ci.a.U2Xn)?1:2);
  endfunction : fullBit
  
  task run_phase(uvm_phase phase);
  begin
    fork
      forever
      begin
        tf.get(ti);
        case(cs)
          txIdle:
            if(ti.txd==0 && ti.txen==1) begin
              cs=txsync;
              syncnt=0;
            end else if(ti.txd==0) begin
              mjerr::err("transmit","start when txen is zero");
            end
          txsync:
            if(ti.txd == 1) begin // false start
              cs=txIdle;
              mjerr::err("transmit","start did not stay low");
            end else begin
              syncnt += 1;
              if(syncnt == halfBit()) begin
                syncnt=0;
                cs=txdata;
                txbpos=0;
                received=0;
                received_parity=0;
              end
            end
          txdata:
            begin
              syncnt += 1;
              if(syncnt >= fullBit()) begin
                received[txbpos]=ti.txd;
//                `uvm_info("debug",$sformatf("bit in %d (%h)--> %h csize %d",txbpos,ti.txd,received,csize),UVM_LOW)
                txbpos += 1;
                syncnt=0;
                received_parity ^= ti.txd;
                if(txbpos == csize) begin
                  if(wdataFifo.is_empty()) begin
                    mjerr::err("transmit","word transmitted when nothing expected");
                    cs=txIdle;
                  end else begin
                    wdataFifo.get(expected);
                    case(csize)
                      5: expected &= 9'h1f;
                      6: expected &= 9'h3f;
                      7: expected &= 9'h7f;
                      8: expected &= 9'hff;
                      9: expected &= 9'h1ff;
                    endcase
                   `uvm_info("debug",$sformatf("got one e %h r %h",expected,received),UVM_LOW)
                    if(received != expected) begin
                      mjerr::err("transmit",$sformatf("expected %h received %h",expected,received));
                    end 
                  end
                  if(ci.c.UPMn[1]) begin // parity
                    cs = txparity;
                  end else begin
                    cs = txstop0;
                  end
                end
              end
            end
          txparity:
            begin
              syncnt += 1;
              if(syncnt >= fullBit()) begin
//                `uvm_info("debug","in parity",UVM_LOW)
                syncnt=1;
                cs = txstop0;
                if((received_parity^ci.c.UPMn[0]) != ti.txd) begin
                  mjerr::err("transmit",$sformatf("parity error e %h r %h %9.0f",received_parity,ti.txd,$realtime));
                end
              end
            end
          txstop0:
            begin
              syncnt += 1;
              if(syncnt >= halfBit()) begin
                syncnt = 2;
                cs = txstop1;
              end
            end
          txstop1:
            begin
              syncnt += 1;
              if(ti.txd == 1'b0) begin
                mjerr::err("transmit","zero seen during stop time");
              end
              if(syncnt >= fullBit()) begin
                syncnt=1;
                if(ci.c.USBSn) begin
                  cs = txstop2;
                end else begin
                  xmit_complete.write(1);
                  cs = txIdle;
                end
              end
            end
          txstop2:
            begin
              syncnt += 1;
              if(ti.txd == 1'b0) begin
                mjerr::err("transmit","zero seen during stop time");
              end
              if(syncnt >= fullBit()) begin
                syncnt=1;
                xmit_complete.write(1);
                cs = txIdle;
              end
            end
          txHang:
            begin
            
            end
          default:
            mjerr::err("TestBenchError","tx state a mess");
        endcase
//        smsg = $sformatf("tx %h en %h",ti.txd,ti.txen);
//        `uvm_info("debug",smsg,UVM_LOW);
      end
    join_none
  end
  endtask : run_phase

  function void report_phase(uvm_phase phase);
    begin
     if(wdataFifo.used() > 0) begin
      `uvm_error("transmit",$sformatf("%4d words left to be transmitted",wdataFifo.used()))
     end
    end
  endfunction : report_phase
  
endclass : txsb0

//
//
// The sequencer to connect the test to the driver
//
//

class u0_seqr extends uvm_sequencer #(u0_si);
  `uvm_object_utils(u0_seqr)
  
  function new(string name="u0_seqr");
    super.new(name);
  endfunction : new

endclass : u0_seqr
//--------------------------------------------------

//
//
// A test for the fun of things...
//
//
class u0_reset extends uvm_sequence #(u0_si);
  `uvm_object_utils(u0_reset)
  u0_si si;
  function new(string name="u0_reset");
    super.new(name);
  endfunction : new

  task doreset();
    begin
      start_item(si);
      si.rst=0;
      si.write=0;
      si.read=0;
      si.wait_tx=0;
      si.addr=8'h22;
      si.din=8'h55;
      finish_item(si);
      repeat(3) begin
        start_item(si);
        si.rst=1;
        si.write=0;
        si.read=0;
        si.addr=8'h55;
        si.din=8'h12;
        finish_item(si);
      end
      si.rst=0;
      repeat(1) begin
        start_item(si);
        si.rst=0;
        si.write=0;
        si.read=0;
        si.addr=8'h55;
        si.din=8'h23;
        finish_item(si);
      end
    
    end
  endtask : doreset
  task body;
    int ix;
    begin
      si=u0_si::type_id::create("si");
      doreset();
    end
  endtask : body

endclass : u0_reset

class u0_seqbase extends uvm_sequence #(u0_si);

  u0_si si;
  
  function new(string name);
    super.new(name);
  endfunction : new
  
  function void build_phase(uvm_phase phase);
  endfunction : build_phase

  
  task busidle();
    begin
      si.rst=0;
      si.write=0;
      si.read=0;
      si.wait_tx=0;
      si.din=$random();
      si.addr=$random();
    end
  endtask : busidle;
  
  task doidle();
    begin
    start_item(si);
    busidle();
    finish_item(si);
    end
  endtask;
  
  task wreg(input [7:0] addr, input [7:0] dv);
    begin
      start_item(si);
      busidle();
      si.write=1;
      si.wait_tx=0;
      si.addr=addr;
      si.din=dv;
      finish_item(si);
    end
  endtask : wreg
  
  task wregw(input [7:0] addr, input [7:0] dv);
    begin
      start_item(si);
      busidle();
      si.write=1;
      si.wait_tx=1;
      si.addr=addr;
      si.din=dv;
      finish_item(si);
    end
  endtask : wregw
  
  task wregw2(input [7:0] addr, input [7:0] dv);
    begin
      start_item(si);
      busidle();
      si.write=1;
      si.wait_tx=1;
      si.addr=addr;
      si.din=dv;
      finish_item(si);
    end
  endtask : wregw2
  
  task wregDelay( input logic[7:0] adr,dat );
    begin
      wreg(adr,dat);
      randcase
        2: repeat(2) doidle();
        2: repeat(1) doidle();
        3: begin
        end
      endcase
    end
  endtask : wregDelay
  
  task setregs(input logic [7:0] Pucsr0a,Pucsr0b,Pucsr0c,
	input [11:0] Pubrr);
    logic [5:0] wv;
    int rv;
    begin
      wv=0;
      while(wv != 6'h3f) begin
        rv=$urandom_range(0,5);
        if(wv[rv]==0) begin
          case (rv)
	    0: wregDelay(u0_si::UCSR0A,Pucsr0a);
	    1: wregDelay(u0_si::UCSR0B,Pucsr0b);
	    2: wregDelay(u0_si::UCSR0C,Pucsr0c);
	    3: wregDelay(u0_si::UBRR0L,Pubrr[7:0]);
	    4: wregDelay(u0_si::UBRR0H,Pubrr[11:8]);
	  endcase
	  wv[rv]=1;
        end
      end
      doidle();
    end
  endtask : setregs
  
  
endclass : u0_seqbase



class u0_setregs extends u0_seqbase;
  `uvm_object_utils(u0_setregs)
  integer ix;
  logic [7:0] ca,cb,cc;
  integer divratio;

  function new(string name="u0_setregs");
    super.new(name);
  endfunction : new
  
  task setvalues(logic [7:0] ra,logic [7:0] rb, logic [7:0] rc,integer dv);
    ca=ra;
    cb=rb;
    cc=rc;
    divratio=dv;
    //`uvm_info("debug",$sformatf("ca %02h cb %02h cc %02h dv %d",ra,rb,rc,dv),UVM_LOW)
  endtask : setvalues
  
  task body;
    begin
      si=u0_si::type_id::create("si");
      si.rst=0;
      si.write=0;
      si.read=0;
      si.wait_tx=0;
      si.addr=8'h22;
      si.din=8'h55;
      setregs(ca,cb,cc,divratio);
      
    end
  endtask : body

endclass : u0_setregs

class u0_sendval0 extends u0_seqbase;
  `uvm_object_utils(u0_sendval0)
  integer ix;
  logic [7:0] ca,cb,cc;
  integer divratio;

  function new(string name="u0_setregs");
    super.new(name);
  endfunction : new
  
  task setvalues(logic [7:0] ra,logic [7:0] rb, logic [7:0] rc,integer dv);
    ca=ra;
    cb=rb;
    cc=rc;
    divratio=dv;
  endtask : setvalues
  
  task body;
    begin
      si=u0_si::type_id::create("si");
      si.rst=0;
      si.write=0;
      si.read=0;
      si.wait_tx=0;
      si.addr=8'h22;
      si.din=8'h55;
      wregw(u0_si::UDR0,8'h12);
      wregw(u0_si::UDR0,8'h13);
      wregw(u0_si::UDR0,8'h14);
      wregw(u0_si::UDR0,8'h15);
      repeat(40) wregw(u0_si::UDR0,$random());
      repeat(19000) doidle();
    end
  endtask : body

endclass : u0_sendval0

class u0_sendval1 extends u0_seqbase;
  `uvm_object_utils(u0_sendval1)
  integer ix;
  logic [7:0] ca,cb,cc;
  integer divratio;

  function new(string name="u0_setregs");
    super.new(name);
  endfunction : new
  
  task setvalues(logic [7:0] ra,logic [7:0] rb, logic [7:0] rc,integer dv);
    ca=ra;
    cb=rb;
    cc=rc;
    divratio=dv;
    `uvm_info("debug",$sformatf("(2) ca %02h cb %02h cc %02h dv %d",ra,rb,rc,dv),UVM_LOW)
  endtask : setvalues
  
  task body;
    begin
      si=u0_si::type_id::create("si");
      si.rst=0;
      si.write=0;
      si.read=0;
      si.wait_tx=0;
      si.addr=8'h22;
      si.din=8'h55;
      repeat(40) begin
        wregw(u0_si::UDR0,$random());
      end
      repeat(30000) doidle();
    end
  endtask : body

endclass : u0_sendval1

//--------------------------------------------

//
//
// The driver
//
//
class u0_drv extends uvm_driver #(u0_si);
  
  `uvm_component_utils(u0_drv)
  
  virtual u0if if0;
  
  u0_si r;
  
  function new(string name="drv",uvm_component par=null);
    super.new(name,par);
  endfunction : new
  
  function void connect_phase(uvm_phase phase);
      if (!uvm_config_db #(virtual u0if)::get(null, "uvm_test_top",
        "u0_if", this.if0)) begin
          `uvm_error("connect", "u0_if not found")
         end 
  endfunction: connect_phase;

  task run_phase(uvm_phase phase);
   begin
    fork
      forever begin
        logic wb=0;
        int safety=100000;
        seq_item_port.get_next_item(r);
        //`uvm_info("deb0",r.toStr(),UVM_LOW)
        if(r.wait_tx) begin
          while(wb==0 && safety > 0) begin
            if0.CB.rst <= 0;
            if0.CB.addr <= u0_si::UCSR0A;
            if0.CB.write <= 0;
            if0.CB.read <= 1;
            @(if0.CB);
            wb=if0.CB.dout[5];
            safety=safety-1;
            if(if0.CB.dout[7]==1 && $urandom_range(0,10)==1) begin
              if0.CB.addr <= u0_si::UCSR0B;
              @(if0.CB);
              if0.CB.addr <= u0_si::UDR0;
              @(if0.CB);
            end
          end
        end
        if(safety <= 0) begin
          `uvm_info("sim issues","timeout waiting for UDRE",UVM_HIGH)
        end
        if0.CB.rst <= r.rst;
        if0.CB.addr <= r.addr;
        if0.CB.write <= r.write;
        if0.CB.read <= r.read;
        if0.CB.din <= r.din;
        //`uvm_info("deb",r.toStr(),UVM_LOW)
        @(if0.CB);
        seq_item_port.item_done();
      end
    join_none
   end
  endtask : run_phase
  
endclass : u0_drv


//
//
// The agent
//
//


class u0_agent extends uvm_agent;
//  u0_seq0 t0;
  u0_reset rst0;
  u0_seqr us0;
  u0_drv drv;
  txmon tm;
  txsb0 tsb0;
  txsbtm tsbtm;
  irsb isb;
  rgsb0 rg0;
  clksb csb;
  tcirmon tirm;
  txirmon tximon;
  sbtcir sbir;
  u0_setregs sr;
  u0_sendval0 sv0;
  u0_sendval1 sv1;
  uvm_analysis_port #(ctl_item) ctlMsg;

  `uvm_component_utils(u0_agent)

function new(string name="u0_agent",uvm_component par = null);
  super.new(name,par);
endfunction : new

function void build_phase(uvm_phase phase);
 begin
  rst0 = u0_reset::type_id::create("reset",this);
  us0 = u0_seqr::type_id::create("seqr",this);
  drv = u0_drv::type_id::create("drv",this);
  tm = txmon::type_id::create("txmon",this);
  tsb0 = txsb0::type_id::create("txsb0",this);
  tsbtm = txsbtm::type_id::create("txsbtm",this);
  isb = irsb::type_id::create("irsb",this);
  rg0 = rgsb0::type_id::create("regsb0",this);
  csb = clksb::type_id::create("clksb",this);
  tirm = tcirmon::type_id::create("tcirmon",this);
  sbir = sbtcir::type_id::create("sbtcir",this);
  ctlMsg = new("ctl_msg",this);
  sr = u0_setregs::type_id::create("u0setregs",this);
  sv0 = u0_sendval0::type_id::create("u0sendval0",this);
  sv1 = u0_sendval1::type_id::create("u0sendval1",this);
  tximon = txirmon::type_id::create("txirmon",this);
  
 end
endfunction : build_phase

function void connect_phase(uvm_phase phase);
 begin
  drv.seq_item_port.connect(us0.seq_item_export);
  tm.txi.connect(tsb0.tf.analysis_export);
  tm.txi.connect(tsbtm.tf.analysis_export);
  tm.txi.connect(isb.tf.analysis_export);
  tm.txi.connect(csb.txi);
  tm.wri.connect(rg0.wfifo.analysis_export);
  rg0.baudMsg.connect(tsb0.bdivMsg);
  rg0.baudMsg.connect(tsbtm.bdivMsg);
  rg0.wdataMsg.connect(tsb0.wdataFifo.analysis_export);
  rg0.csizeMsg.connect(tsb0.csizeMsg);
  rg0.ctlMsg.connect(tsb0.ctlMsg);
  rg0.ctlMsg.connect(tsbtm.ctlMsg);
  rg0.ctlMsg.connect(isb.ctlMsg);
  rg0.ctlMsg.connect(sbir.ctlMsg);
  rg0.ctlMsg.connect(this.ctlMsg);
  rg0.rxtxen.connect(tm.txenMsg);
  rg0.ctlMsg.connect(tm.ctlMsg);
  tsb0.xmit_complete.connect(sbir.xmit_complete);
  
  csb.mcperiod.connect(tsbtm.cperiodMsg);  
  csb.mcperiod.connect(sbir.cper);
 end
endfunction : connect_phase

task run_phase(uvm_phase phase);
endtask : run_phase

endclass : u0_agent
//-----------------------------------------------------------

//
// rx driver
//
class rx_drv extends uvm_driver #(rx_si);
  
  `uvm_component_utils(rx_drv)
  uvm_analysis_imp_ctl #(ctl_item,rx_drv) ctlMsg;
  uvm_analysis_port #(rx_chunk) rx_exp;
  uvm_analysis_imp #(logic [2:0],rx_drv) rx_errs;
  // bit 2 = framing, bit 1=parity, bit 0 = overrun (one day)...
  ctl_item ci;
  
  virtual u0if if0;
  
  rx_si r;
  rx_chunk exp;
  int ix;
  
  logic [2:0] rxe;
  
  logic [8:0] wv;
  logic parity;
  
  function new(string name="rx_drv",uvm_component par=null);
    super.new(name,par);
  endfunction : new
  
  function void build_phase(uvm_phase phase);
    ctlMsg = new("ctl_msg",this);
    rx_exp = new("rx_exp",this);
    rxe=0;
  endfunction : build_phase
  
  function void connect_phase(uvm_phase phase);
      if (!uvm_config_db #(virtual u0if)::get(null, "uvm_test_top",
        "u0_if", this.if0)) begin
          `uvm_error("connect", "u0_if not found")
         end 
  endfunction: connect_phase;
  
  function void write(logic [2:0] rx_errors);
    rxe = rx_errors;
  endfunction : write
  
  function integer bitTime();
    integer wk;
    begin
      wk = (ci.bdiv+1)*8*( (ci.a.U2Xn)?1:2);
      return wk;
    end
  endfunction : bitTime
  
   
  task run_phase(uvm_phase phase);
    begin
      fork
        forever begin
          seq_item_port.get_next_item(r);
//          `uvm_info("debug",r.toStr(),UVM_LOW)
          if0.rxdata <= 1;
          repeat(r.wait_clks) @(if0.CB);
          if0.rxdata <= 0;
          repeat(bitTime()) @(if0.CB);
          wv=r.rxd;
          
          exp = new();
          for(ix=ci.csize; ix < 9; ix=ix+1) begin
            wv[ix]=0;
          end
//          `uvm_info("debug",r.toStr(),UVM_LOW)
          rxe=r.rxe;
          exp.uD=wv[7:0];
          exp.uB.RXB8n=wv[8];
          exp.uA=0;
          exp.uA.FEn = rxe[2];
          exp.uA.UPEn = rxe[1] & ci.c.UPMn[1];
          if(ci.b.RXENn) begin
            rx_exp.write(exp);
//            `uvm_info("debug","wrote an expected",UVM_LOW)
          end
          parity=0;
          repeat(ci.csize) begin
            if0.rxdata <= wv[0];
            parity = parity ^ wv[0];
            wv = wv >> 1;
            repeat(bitTime()) @(if0.CB);
          end
          if(ci.c.UPMn[1]) begin
            if(~ci.c.UPMn[0]) begin
              // even parity
              if0.rxdata <= parity ^ rxe[1];
            end else begin
              if0.rxdata <= (~parity) ^ rxe[1];
            end
            repeat(bitTime()) @(if0.CB);
          end
          if0.rxdata <= (rxe[2])?0:1;
          repeat(bitTime()) @(if0.CB);
          if0.rxdata <= 1;
          if(rxe[2]) repeat(bitTime()) @(if0.CB);
          seq_item_port.item_done();
        end
      join_none
    end
  endtask : run_phase
  
  function void write_ctl(ctl_item cim);
    ci = cim;
//    `uvm_info("debug","rx_drv ci updated",UVM_LOW)
  endfunction : write_ctl
  
  
  
endclass : rx_drv
//
// sequencer for the rx stuff
//
class rx_seqr extends uvm_sequencer #(rx_si);
  `uvm_object_utils(rx_seqr)
  
  function new(string name = "rx_seqr");
    super.new(name);
  endfunction : new
  
endclass : rx_seqr
//
// The sequence for the rx test...
//
class rx_seq extends uvm_sequence #(rx_si);
  `uvm_object_utils(rx_seq)

  rx_si si;
  
  bit b; // not really used, except to finish the run
  
  function new(string name="rx_seq");
    super.new(name);
  endfunction : new
  
  function void build_phase(uvm_phase phase);
  endfunction : build_phase

  task body;
    begin
      si = rx_si::type_id::create("si");
      si.rxe=0;
      b=1;
      while(b) begin
        start_item(si);
        si.rxd=9'h5a;
        si.rxe=0;
        si.wait_clks=2;
        //`uvm_info("debug",$sformatf("rx %03h errv %h",si.rxd,si.rxe),UVM_LOW)
        finish_item(si);
        repeat(20) begin
          start_item(si);
          si.randomize();
          si.rxe=0;
          if($urandom_range(0,100) > 70) si.rxe = ($random()&6);
          //`uvm_info("debug",$sformatf("rx %03h errv %h",si.rxd,si.rxe),UVM_LOW)
          si.wait_clks = $urandom_range(1,4123);
          finish_item(si);
        end
        b=0;
      end
    end
  endtask : body

endclass : rx_seq
//
//
//
class rx_mon extends uvm_monitor;
  `uvm_component_utils(rx_mon)
  
  uvm_analysis_port #(rx_chunk) rxm;

  virtual u0if if0;
  UCSRnA_S uA;
  UCSRnB_S uB;
  logic [7:0] uD;
  
  rx_chunk rc;
  
  function new(string name="rx_mon",uvm_component parent=null);
    super.new(name,parent);
  endfunction : new
  
  function void connect_phase(uvm_phase phase);
    begin
      if (!uvm_config_db #(virtual u0if)::get(null, "uvm_test_top",
          "u0_if", this.if0)) begin
          mjerr::err("connect", "u0_if not found");
      end
    end
  endfunction: connect_phase;
  
  function void build_phase(uvm_phase phase);
    begin
      rxm = new("rxm",this);
      rc = new();
    end
  endfunction : build_phase

  task run_phase(uvm_phase phase);
    begin
      fork
        forever begin
          @(if0.CB);
          if(if0.rst == 0) begin
            if(if0.read==1) begin
              case(if0.addr)
                u0_si::UCSR0A: begin
                  rc.uA = if0.dout;
                end
                u0_si::UCSR0B: begin
                  rc.uB = if0.dout;
                end
                u0_si::UDR0: begin
                  rc.uD = if0.dout;
                  rxm.write(rc);
                end
              endcase
            end
          end
        end
      join_none
    end
  endtask : run_phase

endclass : rx_mon



class rx_sb extends uvm_scoreboard;
  `uvm_component_utils(rx_sb)
  uvm_analysis_imp #(rx_chunk,rx_sb) cmsg;
  uvm_tlm_analysis_fifo #(rx_chunk) expected;
  
  rx_chunk ed;
  
  function new(string name = "rx_sb", uvm_component parent);
    super.new(name,parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
    cmsg = new("cmsg",this);
    expected = new("expected",this);
  endfunction : build_phase
  
  function void cd(logic e,logic r,string msg);
    if(e != r) begin
      `uvm_error("RX",$sformatf("Rec err %s exp %h rec %h",msg,e,r))
      $finish;
    end
  endfunction : cd
  
  function void write(rx_chunk ci);
    begin
//      `uvm_info("debug","read regs seen",UVM_LOW)
      if(expected.is_empty()) begin
        `uvm_error("RX","data received when not expected")
      end else begin
//        `uvm_info("debug","Processing a received item",UVM_LOW)
        expected.try_get(ed);
        if(ed.uD != ci.uD) begin
          `uvm_error("RX",$sformatf("receive data error, exp %02h, rec %02h",ed.uD,ci.uD))
        end
        cd(ed.uB.RXB8n,ci.uB.RXB8n,"RXB8");
        cd(ed.uA.FEn,ci.uA.FEn,"FE");
        cd(ed.uA.UPEn,ci.uA.UPEn,"UPE");
        cd(ed.uA.DORn,ci.uA.DORn,"DOR");
      end
    end
  endfunction : write
  
  function void report_phase(uvm_phase phase);
    if(!expected.is_empty()) begin
      `uvm_error("RX","Not all expected data seen on interface")
    end
  endfunction : report_phase
  
  
endclass : rx_sb

//
// agent for the rx driver
//
class rx_agent extends uvm_agent;
  `uvm_component_utils(rx_agent)
  
  rx_seq rxs;
  rx_seqr rxsr;
  rx_drv rxdrv;
  rx_mon rxm;
  rx_sb  rxsb;
  rxirmon rxmon;
  uvm_analysis_export #(ctl_item) ctlMsg;
  
  function new(string name="rx_agent",uvm_component par=null);
    super.new(name,par);
  endfunction : new
  
  function void build_phase(uvm_phase phase);
    rxs = rx_seq::type_id::create("rxseq",this);
    rxsr = rx_seqr::type_id::create("rxseqr",this);
    rxdrv = rx_drv::type_id::create("rxdrv",this);
    rxm = rx_mon::type_id::create("rx_mon",this);
    rxsb = rx_sb::type_id::create("rx_sb",this);
    rxmon = rxirmon::type_id::create("rx_irmon",this);
    ctlMsg = new("ctl_msg",this);
  endfunction : build_phase
  
  function void connect_phase(uvm_phase phase);
    rxdrv.seq_item_port.connect(rxsr.seq_item_export);
    ctlMsg.connect(rxdrv.ctlMsg);
    rxm.rxm.connect(rxsb.cmsg);
    rxdrv.rx_exp.connect(rxsb.expected.analysis_export);
  endfunction : connect_phase
  
  task run_phase(uvm_phase phase);
  endtask : run_phase

endclass : rx_agent

//
//
// Our environment
//
//
class u0_env extends uvm_env;

u0_agent a0;
rx_agent ra;

integer ix,iy,ip;
  `uvm_component_utils(u0_env)
//`uvm_component_utils_begin(u0_env)
//  `uvm_field_object(a0,UVM_ALL_ON)
//`uvm_component_utils_end

function new(string name="u0_env",uvm_component par=null);
  super.new(name,par);
endfunction : new

function void build_phase(uvm_phase phase);
 begin
  super.build_phase(phase);
  a0=u0_agent::type_id::create("agent",this);
  ra=rx_agent::type_id::create("rx_agent",this);
 end
endfunction : build_phase

function void connect_phase(uvm_phase phase);
  a0.ctlMsg.connect(ra.ctlMsg);
endfunction : connect_phase

task run_phase(uvm_phase phase);
 begin
  `uvm_info("version","1.005",UVM_LOW)
  phase.raise_objection(this, "start of xmit test");
  a0.rst0.start(a0.us0);
  for(ix=0; ix < 5; ix=ix+1) begin
    for(iy=0; iy < 4; iy=iy+1) begin
      if(iy == 1) continue;
      for(ip=0; ip < 2; ip=ip+1) begin
        `uvm_info("debug",$sformatf("case ix %2d iy %2d ip %2d",ix,iy,ip),UVM_LOW)
        a0.sr.setvalues(8'h60,8'h58+(ix&4),8'h00+((ix&4)?3:(ix&3))*2+iy*16+ip*8,22+ix);
        a0.sr.start(a0.us0);
        fork
          a0.sv0.start(a0.us0);
          ra.rxs.start(ra.rxsr);
        join
      end
    end
  end
  `uvm_info("debug","post group 1",UVM_LOW)
  a0.rst0.start(a0.us0);
  a0.sr.setvalues(8'h60,8'h58,8'h22,25);
  a0.sr.start(a0.us0);
  fork
    a0.sv1.start(a0.us0);
    ra.rxs.start(ra.rxsr);
  join
  `uvm_info("debug","post group 2",UVM_LOW)
  a0.sr.setvalues(8'h20,8'h00,8'h30,3);
  a0.sr.start(a0.us0);
  fork
    a0.sv1.start(a0.us0);
    ra.rxs.start(ra.rxsr);
  join
  
  phase.drop_objection(this, "end of xmit test");
 end
 

endtask : run_phase

endclass : u0_env
//--------------------------------------------------------


//
//
// The test class
//
//
class u0_test extends uvm_test;
  u0_env env;
  `uvm_component_utils(u0_test)
  
  function new(string name="u0_test", uvm_component par=null);
    super.new(name,par);
  endfunction : new
  
  function void build_phase(uvm_phase phase);
    env = u0_env::type_id::create("env",this);
  endfunction : build_phase

  function void connect_phase(uvm_phase phase);
  
  endfunction : connect_phase

endclass : u0_test
//---------------------------------------------------


endpackage : u0_pkg

//
// The module for the DUT
//

module top();

import uvm_pkg::*;
import u0_pkg::*;

u0if if0();


initial begin
  if0.clk=0;
  if0.tcack=0;
  if0.txack=0;
  if0.rxack=0;
  if0.rxdata=1;
  forever #5 if0.clk=~if0.clk;
end

initial begin
  if0.rst<=0;
  if0.write<=0;
  if0.read<=0;
  if0.din<=0;
  if0.addr<=8'haa;
end


u0 u(if0.u0);

initial begin
  $dumpfile("u0.vcd");
  $dumpvars(0,top);
end

initial
  begin
    uvm_config_db #(virtual u0if)::set(null, "uvm_test_top", 
      "u0_if" , if0);
//    uvm_factory::get().print();
    run_test("u0_test");
    #10;
    $finish;
  end


endmodule : top
