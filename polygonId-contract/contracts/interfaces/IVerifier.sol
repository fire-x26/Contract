// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

interface IVerifier {
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[] memory input
    ) external view returns (bool r);
}
