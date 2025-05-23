//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// 2019 OKIMS
//      ported to solidity 0.6
//      fixed linter warnings
//      added requiere error messages
//
//
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

import "../lib/Pairing.sol";

contract VerifierSig {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[] IC;
    }
    struct Proof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }

    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(
            20491192805390485299153009773594534940189261866228447918068658471970481763042,
            9383485363053290200918347156157836566562967994039712273449902621266178545958
        );

        vk.beta2 = Pairing.G2Point(
            [
                4252822878758300859123897981450591353533073413197771768651442665752259397132,
                6375614351688725206403948262868962793625744043794305715222011528459656738731
            ],
            [
                21847035105528745403288232691147584728191162732299865338377159692350059136679,
                10505242626370262277552901082094356697409835680220590971873171140371331206856
            ]
        );
        vk.gamma2 = Pairing.G2Point(
            [
                11559732032986387107991004021392285783925812861821192530917403151452391805634,
                10857046999023057135944570762232829481370756359578518086990519993285655852781
            ],
            [
                4082367875863433681332203403145435568316851327593401208105741076214120093531,
                8495653923123431417604973247489272438418190587263600148770280649306958101930
            ]
        );
        vk.delta2 = Pairing.G2Point(
            [
                9233349870741476556654282208992970742179487991957579201151126362431960413225,
                1710121669395829903049554646654548770025644546791991387060028241346751736139
            ],
            [
                19704486125052989683894847401785081114275457166241990059352921424459992638027,
                19046562201477515176875600774989213534306185878886204544239016053798985855692
            ]
        );
        vk.IC = new Pairing.G1Point[](12);

        vk.IC[0] = Pairing.G1Point(
            4329040981391513141295391766415175655220156497739526881302609278948222504970,
            284608453342683033767670137533198892462004759449479316068661948021384180405
        );

        vk.IC[1] = Pairing.G1Point(
            7902292650777562978905160367453874788768779199030594846897219439327408939067,
            10012458713202587447931138874528085940712240664721354058270362630899015322036
        );

        vk.IC[2] = Pairing.G1Point(
            11697814597341170748167341793832824505245257771165671796257313346092824905883,
            5174781854368103007061208391170453909797905136821147372441461132562334328215
        );

        vk.IC[3] = Pairing.G1Point(
            1726927835877229859131056157678822776962440564906076714962505486421376544987,
            7352133740317971386526986860674287355620937922375271614467789385331477610856
        );

        vk.IC[4] = Pairing.G1Point(
            9990035903997574691712818787908054784756674039249764811431700936009293741830,
            4755447104942954158928166153067753327016299728030535979210293681329469052797
        );

        vk.IC[5] = Pairing.G1Point(
            15940583140274302050208676622092202988851114679125808597061574700878232173357,
            7533895757575770389928466511298564722397429905987255823784436733572909906714
        );

        vk.IC[6] = Pairing.G1Point(
            5508259264227278997738923725524430810437674978357251435507761322739607112981,
            14840270001783263053608712412057782257449606192737461326359694374707752442879
        );

        vk.IC[7] = Pairing.G1Point(
            19432593446453142673661052218577694238117210547713431221983638840685247652932,
            16697624670306221047608606229322371623883167253922210155632497282220974839920
        );

        vk.IC[8] = Pairing.G1Point(
            6174854815751106275031120096370935217144939918507999853315484754500615715470,
            3190247589562983462928111436181764721696742385815918920518303351200817921520
        );

        vk.IC[9] = Pairing.G1Point(
            20417210161225663628251386960452026588766551723348342467498648706108529814968,
            13308394646519897771630385644245620946922357621078786238887021263713833144471
        );

        vk.IC[10] = Pairing.G1Point(
            1439721648429120110444974852972369847408183115096685822065827204634576313044,
            7403516047177423709103114106022932360673171438277930001711953991194526055082
        );

        vk.IC[11] = Pairing.G1Point(
            18655728389101903942401016308093091046804775184674794685591712671240928471338,
            15349580464155803523251530156943886363594022485425879189715213626172422717967
        );
    }

    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.IC.length, "verifier-bad-input");
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field, "verifier-gte-snark-scalar-field");
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.IC[0]);
        if (
            !Pairing.pairingProd4(
                Pairing.negate(proof.A),
                proof.B,
                vk.alfa1,
                vk.beta2,
                vk_x,
                vk.gamma2,
                proof.C,
                vk.delta2
            )
        ) return 1;
        return 0;
    }

    /// @return r  bool true if proof is valid
    function verifyProof(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[11] memory input
    ) public view returns (bool r) {
        // slither-disable-next-line uninitialized-local
        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        uint[] memory inputValues = new uint[](input.length);
        for (uint i = 0; i < input.length; i++) {
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}
