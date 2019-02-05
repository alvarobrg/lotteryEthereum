pragma solidity ^0.5.1;

contract Ownable {

    address public owner = msg.sender;
    // adress zero = 0x0000000000000000000000000000000000000000;
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }
}


contract Lottery is Ownable{
    
    Game[] ListGames ;
    uint price = 25000000000000000;
    uint[qntNumbers] winnerGame ;
    address payable[]  ListWinners;
    //winnerGame = [1,2,3,4,5,6,7,8];
    uint winnersPayed = 0;
    uint expiredGames = 0;
    uint constant qntNumbers  = 8;
    uint constant numberMax = 60;
    uint[] games;
    uint timerDelay = 60;
    uint lastGameTime= now;
    
    struct Game{
        
        address payable gamer;
        uint[qntNumbers] numbers;
        uint date;
        bool valid;
        
    }
    
    event trace(bytes32 x, bytes4 a, bytes4 b,bytes4 c,bytes4 d,bytes4 e,bytes4 f,bytes4 g,bytes4 h);
    event numbersCheck(uint a,uint b,uint c,uint d,uint e,uint f,uint g,uint h);
    event tabCheck(uint[8] tab);
    event hassh(bytes32 a);

    function setWinner() public {
        
        if (lastGameTime+timerDelay<=now){
        
 
        bytes4[8] memory x = [bytes4(0) , 0 ,0,0,0,0,0,0 ];
        
        
        uint blockNumber = block.number;
        bytes32 blockHash1 = blockhash(blockNumber-1);
        bytes32 blockHash6 = blockhash(blockNumber-6);
        bytes32 blockHash13 = blockhash(blockNumber-13);
        
        bytes32 hash = keccak256(abi.encodePacked(now,ListWinners,games,blockHash1,blockHash6,blockHash13));
        
        
        assembly {
            mstore(x, hash)
            mstore(add(x, 28), hash)
            mstore(add(x, 56), hash)
            mstore(add(x, 84), hash)
            mstore(add(x, 112), hash)
            mstore(add(x, 140), hash)
            mstore(add(x, 168), hash)
            mstore(add(x, 196), hash)
        }
        
        uint n0 = uint32 (x[0]); 
        n0 = n0%numberMax;
        uint n1 = uint32 (x[1]); 
        n1 = n1%numberMax;
        uint n2 = uint32 (x[2]); 
        n2 = n2%numberMax;
        uint n3 = uint32 (x[3]); 
        n3 = n3%numberMax;
        uint n4 = uint32 (x[4]); 
        n4 = n4%numberMax;
        uint n5 = uint32 (x[5]); 
        n5 = n5%numberMax;
        uint n6 = uint32 (x[6]); 
        n6 = n6%numberMax;
        uint n7 = uint32 (x[7]); 
        n7 = n7%numberMax;
        
        uint[qntNumbers] memory tabNumbers = [n0,n1,n2,n3,n4,n5,n6,n7];
        
        quickSort(tabNumbers,0,tabNumbers.length -1);
        
        removeDoubles(tabNumbers);
        
        winnerGame = tabNumbers;
        
        payer();
        
        lastGameTime = now;
        
        }
        
    }
    
    function removeDoubles(uint[qntNumbers] memory tab) private{
        
        bool a=true;
        bool b=true;
        bool c=true;
        bool d=true;
        
       
            for (uint i=0;i<tab.length;i++){
                
                if(tab[0]==0){
                    tab[0]=60;
                }
                
                if (tab[i]> numberMax){
                    tab[i] = tab[i]%numberMax;
                    b=false;
                }
                
                if ( (i+1 < tab.length)&& (tab[i]==tab[i+1])){
                    
                    tab[i+1]= tab[i+1] + 1;
                    c=false;
               }
            }
            
            if(a&&b&&c&&d){
                quickSort(tab,0,tab.length -1);
                emit tabCheck(tab);
                return;
            }
            
            quickSort(tab,0,tab.length -1);
            
            removeDoubles(tab);
         
    }
    
    function quickSort(uint[qntNumbers] memory tab, uint left, uint right) private {
        uint i = left;
        uint j = right;
        uint mid = tab[left + (right - left) / 2];
        while (i <= j) {
            while (tab[i] < mid) i++;
            while (mid < tab[j]) j--;
            if (i <= j) {
                (tab[i], tab[j]) = (tab[j], tab[i]);
                i++;
                j--;
            }
        }
        if (left < j)
            quickSort(tab, left, j);
        if (i < right)
            quickSort(tab, i, right);
        
    }
    
    function findWinners() private returns (address payable[] memory){
        uint size = ListGames.length;
        bool win;
        
        
        for (uint j=0; j<size ; j++  ){
            win=true;
            for (uint i=0; i<qntNumbers ; i++){
                if ((ListGames[j].numbers[i] != winnerGame[i]) || !ListGames[j].valid){
                    win = false;
                }
            }
            
            if (win){
                ListGames[j].valid = false;
                expiredGames ++;
                ListWinners.push(ListGames[j].gamer);
            }
        }
        
        return ListWinners;
    }
    
    function payer() private returns (uint) {
        uint nbWinners=findWinners().length;
        uint prize;   
            if (nbWinners- winnersPayed !=0){
                
                prize = address(this).balance/(nbWinners- winnersPayed);
                for (uint i=0;i<nbWinners;i++){
                
                    if(ListWinners[i]!=address(0)){
                        ListWinners[i].transfer(prize);
                        delete ListWinners[i];
                        winnersPayed ++;
                        require(ListWinners[i]==address(0));
                    }
                }
            }
        
       return nbWinners;
        
    }
        
   modifier costs(uint amount){
        require(msg.value >= amount);
        _;
    }
    
    function postGame(uint[qntNumbers] memory _numbers) public payable costs(price){
        
        Game memory newGame = Game(msg.sender,_numbers,block.timestamp,true);
        ListGames.push(newGame);
        
        
    }
    
    function numberValidGames() public view returns (uint){
        
        return ListGames.length - expiredGames;
    }
 
    function getTimeNextGame() public view returns (uint){
        
        uint time = timerDelay + lastGameTime - now ;
        if (time>timerDelay){
            time=0;
        }
        
        return time;
    }
    
    function getComulatedPrize() public view returns (uint){
        return address(this).balance;
        
    }
    function getGamesList() private returns (uint[] memory){
        
        uint size = ListGames.length;
        games = [uint(0)];
        
        for (uint i = 0; i<size;i++){
                for (uint j = 0; j< qntNumbers;j++){
                uint gameNumberCurrent = ListGames[i].numbers[j];
                games.push(gameNumberCurrent);
                }
        }
        return games;
    }
    
}

