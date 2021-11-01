#!/usr/bin/python3

from brownie import *
import hashlib

def main():
    # deploy da biblioteca de commit
    owner = accounts[0]

    SimpleCommit.deploy({'from':owner})
    
    # deploy do contrato
    simpleSchellingCoin.deploy({"from":owner, "value":"10 ether"})
    address = simpleSchellingCoin[0].address
    contrato = simpleSchellingCoin.at(address)

    contrato.adicionaParticipante({"from":accounts[1]})
    contrato.adicionaParticipante({"from":accounts[2]})
    contrato.adicionaParticipante({"from":accounts[3]})

    contrato.coletaVoto(b"teste1",{"from":accounts[1]})
    contrato.coletaVoto(b"teste2",{"from":accounts[2]})
    contrato.coletaVoto(b"teste3",{"from":accounts[3]})

    contrato.revelaVoto({"from":accounts[1]})




