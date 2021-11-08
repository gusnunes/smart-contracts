pragma solidity >=0.4.25 <0.6.0;

import "./simpleSchellingCoin.sol";

contract Bribe {
    simpleSchellingCoin schelling;
    address payable dono;

    // endereços dos participantes subornados
    mapping(address => bool) public subornados;

    // valor do suborno
    uint epsilon;

    // deposito do suborno para pagar os participantes
    uint deposito;

    uint qtd_subornados;
    uint qtd_atual; // controla qtd atual de subornados adicionados

    enum StatesType {aguardaSubornados,pagaSubornados,fim}
    StatesType state;

    constructor (address schelling_endereco, uint quantidade) public payable {
        dono = msg.sender;
        schelling = simpleSchellingCoin(schelling_endereco);
        
        epsilon = 0.5 ether;
        qtd_subornados = quantidade;
        deposito = qtd_subornados * epsilon;

        require(msg.value >= deposito, "Deposito tem valor minimo");
        state = StatesType.aguardaSubornados;
        qtd_atual = 0;
    }

    // adicionar endereço dos subornados
    function adicionaSubornado(address participante) public {
        require (state == StatesType.aguardaSubornados);
        require (msg.sender == dono, "Somente o dono adiciona enderecos");
        
        // participante eh cadastrado apenas uma vez
        require (subornados[participante] == false, "Endereco ja cadastrado!");
        subornados[participante] = true;
        
        qtd_atual += 1;

        if (qtd_atual == qtd_subornados){
            state = StatesType.pagaSubornados;
        }
    }

    function pagaSubornados() external payable {
        require (state == StatesType.pagaSubornados);
        require (msg.sender == dono);
        
        address payable[] memory participantes = schelling.getSimParticipantes();
        uint tamanho = participantes.length;
        address payable participante_endereco;
        
        for(uint i=0; i<tamanho; i++){
            participante_endereco = participantes[i];
            
            // paga somente se for um participante subornado
            if(subornados[participante_endereco]){
                participante_endereco.transfer(epsilon); // paga o suborno
            }  
        }

        // dinheiro que ficou no contrato volta pro dono
        dono.transfer(address(this).balance);
        
        state = StatesType.fim;
    }

}