// Copyright 2016 Tudor Timisescu (verificationgentleman.com)
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.



`include "svunit_uvm_mock_pkg.sv"


module master_driver_unit_test;
  import svunit_pkg::svunit_testcase;
  import svunit_uvm_mock_pkg::*;
  `include "svunit_defines.svh"

  import vgm_svunit_utils::*;

  string name = "master_driver_ut";
  svunit_testcase svunit_ut;

  import vgm_wb::*;
  import uvm_pkg::*;

  master_driver driver;


  sequencer_stub #(sequence_item) sequencer;

  bit rst = 1;
  bit clk;
  always #1 clk = ~clk;

  vgm_wb_master_interface intf(rst, clk);


  function void build();
    svunit_ut = new(name);

    driver = new("driver", null);
    sequencer = new("sequencer", null);
    driver.seq_item_port.connect(sequencer.seq_item_export);
    driver.intf = intf;

    svunit_deactivate_uvm_component(driver);
  endfunction


  task setup();
    svunit_ut.setup();
    reset_signals();
    svunit_activate_uvm_component(driver);
    svunit_uvm_test_start();
  endtask


  task teardown();
    svunit_ut.teardown();
    svunit_uvm_test_finish();
    svunit_deactivate_uvm_component(driver);
  endtask



  `SVUNIT_TESTS_BEGIN

    `SVTEST(cyc_and_stb_driven)
      sequence_item item = new("item");
      sequencer.add_item(item);

      @(posedge clk);
      `FAIL_UNLESS(intf.CYC_O === 1)
      `FAIL_UNLESS(intf.STB_O === 1)
    `SVTEST_END


    `SVTEST(cyc_and_stb_driven_with_delay)
      sequence_item item = new("item");
      item.delay = 3;
      sequencer.add_item(item);

      repeat (3) begin
        @(posedge clk);
        `FAIL_UNLESS(intf.CYC_O === 0)
        `FAIL_UNLESS(intf.STB_O === 0)
      end

      @(posedge clk);
      `FAIL_UNLESS(intf.CYC_O === 1)
      `FAIL_UNLESS(intf.STB_O === 1)
    `SVTEST_END


    `SVTEST(read_transfer_driven)
      sequence_item item = new("item");
      item.direction = READ;
      item.address = 'haabb_ccdd;
      sequencer.add_item(item);

      @(posedge clk);
      `FAIL_UNLESS(intf.WE_O === 0)
      `FAIL_UNLESS(intf.ADR_O === 'haabb_ccdd)
    `SVTEST_END


    `SVTEST(write_transfer_driven)
      sequence_item item = new("item");
      item.direction = WRITE;
      item.address = 'h1122_3344;
      sequencer.add_item(item);

      @(posedge clk);
      `FAIL_UNLESS(intf.WE_O === 1)
      `FAIL_UNLESS(intf.ADR_O === 'h1122_3344)
    `SVTEST_END


    `SVTEST(transfer_held_until_ack)
      sequence_item item = new("item");
      intf.ACK_I <= 0;
      sequencer.add_item(item);

      repeat (3) begin
        @(posedge clk);
        `FAIL_UNLESS(intf.CYC_O === 1)
        `FAIL_UNLESS(intf.STB_O === 1)
      end

      intf.ACK_I <= 1;
      @(posedge clk);
      `FAIL_UNLESS(intf.CYC_O === 1)
      `FAIL_UNLESS(intf.STB_O === 1)
    `SVTEST_END


    `SVTEST(idle_after_ack)
      sequence_item item = new("item");
      intf.ACK_I <= 0;
      sequencer.add_item(item);

      repeat (5)
        @(posedge clk);

      intf.ACK_I <= 1;
      @(posedge clk);

      @(posedge clk);
      `FAIL_UNLESS(intf.CYC_O === 0)
      `FAIL_UNLESS(intf.STB_O === 0)
    `SVTEST_END

  `SVUNIT_TESTS_END


  task reset_signals();
    intf.CYC_O = 0;
    intf.STB_O = 0;
    intf.ACK_I = 1;
  endtask

endmodule
