// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "./interface/IERC20.sol";
import "./lib/SafeTransfer.sol";

contract Sandwich {
    using SafeTransfer for IERC20;

    // 認証済み
    address internal immutable user;

    // transfer(address,uint256)の関数ID
    bytes4 internal constant ERC20_TRANSFER_ID = 0xa9059cbb;

    // swap(uint256,uint256,address,bytes)の関数ID
    bytes4 internal constant PAIR_SWAP_ID = 0x022c0d9f;

    // コンストラクタは唯一のユーザーを設定します
    receive() external payable {}

    constructor(address _owner) {
        user = _owner;
    }

    // *** コントラクトからの利益を受け取る *** //
    function recoverERC20(address token) public {
        require(msg.sender == user, "立ち去る");
        IERC20(token).safeTransfer(
            msg.sender,
            IERC20(token).balanceOf(address(this))
        );
    }

    /*
        フロントスライスとバックスライスを行うフォールバック関数

        アンクルブロック保護はありません、自己責任で使用してください

        ペイロード構造 (abi encodePacked)

        - token: address        - スワップするトークンのアドレス
        - pair: address         - サンドイッチに使用するUniv2ペア
        - amountIn: uint128     - スワップで提供する量
        - amountOut: uint128    - スワップで受け取る量
        - tokenOutNo: uint8     - 提供するトークンはtoken0かtoken1か？ (Univ2ペア上)

        注: このフォールバック関数はいくつかのぶら下がりビットを生成します
    */
    fallback() external payable {
        // アセンブリはイミュータブル変数を読み取ることができません
        address memUser = user;

        assembly {
            // 認証されたユーザーのみがフォールバック関数にアクセスできます
            if iszero(eq(caller(), memUser)) {
                // Ohm (3, 3) はコードをより効率的にします
                // WGMI
                revert(3, 3)
            }

            // 変数を抽出します
            // 関数シグネチャがないので、さらにガスを節約します

            // bytes20
            let token := shr(96, calldataload(0x00))
            // bytes20
            let pair := shr(96, calldataload(0x14))
            // uint128
            let amountIn := shr(128, calldataload(0x28))
            // uint128
            let amountOut := shr(128, calldataload(0x38))
            // uint8
            let tokenOutNo := shr(248, calldataload(0x48))

            // **** token.transfer(pair, amountIn) を呼び出します ****

            // transfer関数のシグネチャ
            mstore(0x7c, ERC20_TRANSFER_ID)
            // 宛先
            mstore(0x80, pair)
            // 量
            mstore(0xa0, amountIn)

            let s1 := call(sub(gas(), 5000), token, 0, 0x7c, 0x44, 0, 0)
            if iszero(s1) {
                // WGMI
                revert(3, 3)
            }

            // ************
            /*
                pair.swap(
                    tokenOutNo == 0 ? amountOut : 0,
                    tokenOutNo == 1 ? amountOut : 0,
                    address(this),
                    new bytes(0)
                ) を呼び出します
            */

            // swap関数のシグネチャ
            mstore(0x7c, PAIR_SWAP_ID)
            // tokenOutNo == 0 ? ....
            switch tokenOutNo
            case 0 {
                mstore(0x80, amountOut)
                mstore(0xa0, 0)
            }
            case 1 {
                mstore(0x80, 0)
                mstore(0xa0, amountOut)
            }
            // address(this)
            mstore(0xc0, address())
            // 空のバイト
            mstore(0xe0, 0x80)

            let s2 := call(sub(gas(), 5000), pair, 0, 0x7c, 0xa4, 0, 0)
            if iszero(s2) {
                revert(3, 3)
            }
        }
    }
}
