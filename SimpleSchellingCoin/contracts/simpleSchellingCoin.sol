pragma solidity >=0.4.25 <0.6.0;

import "./SimpleCommit.sol";

contract simpleSchellingCoin {
    using SimpleCommit for SimpleCommit.CommitType;

    // constantes que representam voto sim ou voto nao
    byte sim = byte(0x01);
    byte nao = byte(0x00);

    // endereços dos participantes de acordo com o voto
    address payable[] public sim_participantes;
    address payable[] public nao_participantes;
    
    // cada participante tem um commit do seu voto
    mapping(address => SimpleCommit.CommitType) public commits;
    
    address payable dono;
    
    // deposito para pagar os participantes
    uint deposito;

    uint qtd_participantes;
    uint qtd_atual; // controla qtd atual de participantes, votos e revelações

    // endereços dos participantes cadastrados
    mapping(address => bool) public enderecos;

    // controla se participante fez commit do voto
    mapping(address => bool) public commited;

    // controla se participante revelou voto
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

    // adicionar endereço do participante
    function adicionaParticipante(address participante) public {
        require (state == StatesType.aguardaParticipantes);
        require (msg.sender == dono, "Somente o dono adiciona partipantes");
        
        // participante eh cadastrado apenas uma vez
        require (enderecos[participante] == false, "Participante ja cadastrado!");
        enderecos[participante] = true;
        
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

        // somente se participante revelou corretamente o commit
        if (commits[msg.sender].isCorrect()){
            // contabiliza somente os votos "sim" ou "nao"
            byte voto = commits[msg.sender].getValue();
            
            if (voto == sim){
                sim_participantes.push(msg.sender);
            }
            else if (voto == nao) {
                nao_participantes.push(msg.sender);
            }
        }

        // quantidade de participantes que revelaram o voto
        qtd_atual += 1;

        if (qtd_atual == qtd_participantes){
            state = StatesType.pagaVencedores;
            //qtd_atual = 0;
        }
    }

    function pagaVencedores() public {
        require (state == StatesType.pagaVencedores);
        require (msg.sender == dono);

        address payable vencedor;
        uint qtd_sim = sim_participantes.length;
        uint qtd_nao = nao_participantes.length;

        // voto "sim" venceu ou deu empate
        if(qtd_sim >= qtd_nao){
            for(uint i=0; i<qtd_sim; i++){
                vencedor = sim_participantes[i];
                vencedor.transfer(P);
            }
        }
        // voto "não" venceu
        else {
            for(uint i=0; i<qtd_nao; i++){
                vencedor = nao_participantes[i];
                vencedor.transfer(P);
            }  
        }
    }

    // pagar os vencedores
    // lucro(?)
    // funcao view para saber o resultado
}
