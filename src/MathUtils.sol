// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title MathUtils
/// @notice A library for common mathematical utility functions.
library MathUtils {
    /// @notice Returns the smaller of two unsigned integers.
    /// @param a The first unsigned integer.
    /// @param b The second unsigned integer.
    /// @return The smaller of the two input values.
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /// @notice Returns the larger of two unsigned integers.
    /// @param a The first unsigned integer.
    /// @param b The second unsigned integer.
    /// @return The larger of the two input values.
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /// @notice Calculates a percentage of a given amount.
    /// @param amount The total amount.
    /// @param percentage The percentage to calculate (e.g., 10 for 10%).
    /// @return The calculated percentage of the amount.
    function calculatePercentage(uint256 amount, uint256 percentage)
        internal
        pure
        returns (uint256)
    {
        // Solidity 0.8.0+ handles overflow/underflow checks automatically.
        // We multiply first to maintain precision, then divide.
        // This might truncate decimals, which is generally acceptable for integer percentages.
        return (amount * percentage) / 100;
    }
}
