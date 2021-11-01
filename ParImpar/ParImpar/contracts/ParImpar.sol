pragma solidity >=0.4.25 <0.6.0;

import "./SimpleCommit.sol";

contract parImpar {

  using SimpleCommit for SimpleCommit.CommitType;

  enum StatesType {aguardaJogador, revelaValores, revelado, fim}

  SimpleCommit.CommitType valorDono;
  SimpleCommit.CommitType valorJogador;

  address payable dono;
  address payable jogador;

  uint256 valorAposta;
  uint256 limiteBloco;

  StatesType myState;

  // saber se os jogadors já reveleram o commit
  bool donoRevealed = false;
  bool jogadorRevealed = false;

  constructor (bytes32 _vD) public payable {
      valorDono.commit(_vD);
      valorAposta = msg.value;
      limiteBloco = block.number + 10;
      dono = msg.sender;
      myState = StatesType.aguardaJogador;
  }

  function entraJogo(bytes32 _vJ) public payable {
    // Dono precisa ter iniciado o jogo
    require (myState == StatesType.aguardaJogador);
    require (msg.value >= valorAposta, "Aposta tem valor minimo!!!");
    
    // atualiza estado do contrato 
    valorJogador.commit(_vJ);
    jogador = msg.sender;
    
    // armazena _vJ e msg.sender
    myState = StatesType.revelaValores;
  }

  function donoRevela(byte value, bytes32 nonce) public {
    require (msg.sender == dono);
    require (myState == StatesType.revelaValores);

    valorDono.reveal(nonce,value);
    donoRevealed = true;
  }

  function jogadorRevela(byte value, bytes32 nonce) public {
    require (msg.sender == jogador);
    require (myState == StatesType.revelaValores);

    valorJogador.reveal(nonce,value);
    jogadorRevealed = true;
  }

  function pagaVencedor() public {
    // jogadores devem pelo menos ter iniciado o jogo (ambos)
    // Não necessariamente terem revelado o commit
    require (myState == StatesType.revelaValores);

    // bloco passou do limite
    if (block.number > limiteBloco) {
      // Encerra o jogo
      myState = StatesType.fim;
      
      // jogador não revelou
      if (donoRevealed && !jogadorRevealed){
        dono.transfer(address(this).balance);
      }
      
      // dono não revelou
      else if (!donoRevealed && jogadorRevealed){
        jogador.transfer(address(this).balance);
      }
    }
    
    else {
      // jogadores precisam ter revelado os commits
      require (donoRevealed && jogadorRevealed);

      // Encerra o jogo
      myState = StatesType.fim;
      
      // dono não revelou corretamente
      if (!(valorDono.isCorrect()) && valorJogador.isCorrect()){
        jogador.transfer(address(this).balance);
      }
      
      // jogador não revelou corretamente
      else if (valorDono.isCorrect() && !(valorJogador.isCorrect())){
        dono.transfer(address(this).balance);
      }

      // ambos revelaram correto
      else if (valorDono.isCorrect() && valorJogador.isCorrect()){
        uint soma;
        soma = uint8(valorDono.getValue()) + uint8(valorJogador.getValue());
        
        // dono ganhar com par
        if (soma % 2 == 0){
          dono.transfer(address(this).balance);
        }
        // jogador ganha com impar
        else {
          jogador.transfer(address(this).balance);
        }
      }
    }
  }

}