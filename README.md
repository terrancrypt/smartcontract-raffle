# Provably Random Raffle Contract


## About
Code này dùng để tạo một smart contract sổ xố (lottery smart contract)

## Chúng ta muốn code này làm gì?
1. Người dùng có thể trả tiền để mua vé (ticket)
Phí mua vé sẽ được chuyển đến người chiến thắng trong khi xổ số
2. Sau một khoảng thời gian nhất định, xổ số sẽ tự động được xổ và tìm ra người chiến thắng
3. Sử dụng Chainlink VRF & Chainlink automation
- Chainlink VRF để random
- Chailink Automation để tự động kích hoạt sổ xố

## Test
1. Viết deploy scripts
2. Viết test case
   1. Hoạt động trên local chain
   2. Forked testnet
   3. Forked mainnet