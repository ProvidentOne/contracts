library ConvertLib{
	function convert(uint amount,uint conversionRate) returns (uint convertedAmount)
	{
		return amount * conversionRate;
	}

	function finneyToWei(uint amountWei) returns (uint) {
		return convert(amountWei, (1 finney / 1 wei));
	}

	function etherToWei(uint amountWei) returns (uint) {
		return convert(amountWei, (1 ether / 1 wei));
	}
}
