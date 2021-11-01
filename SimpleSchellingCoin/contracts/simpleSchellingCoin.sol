pragma solidity >=0.4.25 <0.6.0;

import "./SimpleCommit.sol";

contract simpleSchellingCoin {
    using SimpleCommit for SimpleCommit.CommitType;

    // constantes que representam voto sim ou voto nao
    byte sim = byte(0x01);
    byte nao = byte(0x00);
    
    // cada participante tem um commit do seu voto
    mapping(address => SimpleCommit.CommitType) public commits;
    
    address payable dono;
    
    // deposito para pagar os participantes
    uint deposito;

    uint qtd_participantes;
    uint qtd_atual; // controla qtd atual de participantes, votos e commit

    // endereços dos participantes cadastrados
    mapping(address => bool) public enderecos;

    // verifica se participante fez commit do voto
    mapping(address => bool) public commited;

    // verifica se participante revelou voto
    mapping(address => bool) public revealed;

    enum StatesType {aguardaParticipantes,aguardaVotos,aguardaRevelacao,pagaVencedores}
    StatesType state;
    
    // def do valor de P, deposito para pagar os participantes
    uint P;
    
    constructor () public payable {
        P = 1 ether;
        qtd_participantes = 3;
        qtd_atual = 0;
        deposito = qtd_participantes * P;
        
        // pensar se precisa do limite do bloco
        //limiteBloco = block.number + 10;
        
        dono = msg.sender;
        
        state = StatesType.aguardaParticipantes;
    }

    // adicionar endereços
    function adicionaParticipante() public {
        require (state == StatesType.aguardaParticipantes);
        
        // participante se cadastra apenas uma vez
        require (enderecos[msg.sender] == false, "Participante ja se cadastrou!");

        enderecos[msg.sender] = true;
        qtd_atual += 1;

        if (qtd_atual == qtd_participantes){
            state = StatesType.aguardaVotos;
            qtd_atual = 0;
        }
    }
    
    function coletaVoto(bytes32 c) public {
        require (state == StatesType.aguardaVotos);
        require (enderecos[msg.sender], "Participante nao cadastrado!");

        // participante faz commit apenas uma vez
        require (commited[msg.sender] == false, "Participante ja comitou voto!");
        commited[msg.sender] = true;
        
        // faz commit do voto
        commits[msg.sender].commit(c);

        qtd_atual += 1;

        if (qtd_atual == qtd_participantes){
            state = StatesType.aguardaRevelacao;
            qtd_atual = 0;
        }
    }

    function revelaVoto(bytes32 nonce, byte value) public {
        require (state == StatesType.aguardaRevelacao);
        require (enderecos[msg.sender], "Participante nao cadastrado!");

        // participante revela voto apenas uma vez
        require (revealed[msg.sender] == false, "Participante ja revelou voto!");
        revealed[msg.sender] = true;

        // revela o voto
        commits[msg.sender].reveal(nonce,value);

        qtd_atual += 1;

        if (qtd_atual == qtd_participantes){
            state = StatesType.pagaVencedores;
            qtd_atual = 0;
        }
    }

    // pagar os vencedores
    // lucro(?)
    // funcao view para saber o resultado
}
