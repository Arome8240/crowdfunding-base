// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/MathUtils.sol";

contract MathUtilsTest is Test {
    function test_Min() public {
        assertEq(MathUtils.min(1, 2), 1, "min(1, 2) should be 1");
        assertEq(MathUtils.min(2, 1), 1, "min(2, 1) should be 1");
        assertEq(MathUtils.min(1, 1), 1, "min(1, 1) should be 1");
        assertEq(MathUtils.min(0, 1), 0, "min(0, 1) should be 0");
        assertEq(MathUtils.min(1, 0), 0, "min(1, 0) should be 0");
        assertEq(
            MathUtils.min(type(uint256).max, 0),
            0,
            "min(max_uint, 0) should be 0"
        );
    }

    function test_Max() public {
        assertEq(MathUtils.max(1, 2), 2, "max(1, 2) should be 2");
        assertEq(MathUtils.max(2, 1), 2, "max(2, 1) should be 2");
        assertEq(MathUtils.max(1, 1), 1, "max(1, 1) should be 1");
        assertEq(MathUtils.max(0, 1), 1, "max(0, 1) should be 1");
        assertEq(MathUtils.max(1, 0), 1, "max(1, 0) should be 1");
        assertEq(
            MathUtils.max(type(uint256).max, 0),
            type(uint256).max,
            "max(max_uint, 0) should be max_uint"
        );
    }

    function test_CalculatePercentage() public {
        assertEq(
            MathUtils.calculatePercentage(100, 10),
            10,
            "10% of 100 should be 10"
        );
        assertEq(
            MathUtils.calculatePercentage(200, 25),
            50,
            "25% of 200 should be 50"
        );
        assertEq(
            MathUtils.calculatePercentage(0, 50),
            0,
            "50% of 0 should be 0"
        );
        assertEq(
            MathUtils.calculatePercentage(100, 0),
            0,
            "0% of 100 should be 0"
        );
        assertEq(
            MathUtils.calculatePercentage(100, 100),
            100,
            "100% of 100 should be 100"
        );
        assertEq(
            MathUtils.calculatePercentage(123, 13),
            15,
            "13% of 123 should be 15 (integer truncation)"
        );
    }
}
