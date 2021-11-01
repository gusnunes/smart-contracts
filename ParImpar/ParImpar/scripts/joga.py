#!/usr/bin/python3

from brownie import *
import brownie
import hashlib

def createNonce(s):
    n = hashlib.sha256()
    n.update(s)
    return n.digest()

def doCommit(n,v):
    c = hashlib.sha256()
    c.update(n)
    c.update(v)
    return c.digest()

def main():
    # deploy da biblioteca de commit
    dono = accounts[0]
    SimpleCommit.deploy({'from':dono})

    valor_dono = b'2'
    nonce_dono = createNonce(b'nonce1')
    commit_dono = doCommit(nonce_dono,valor_dono)
    
    # deploy do jogo
    parImpar.deploy(commit_dono,{"from":dono, "value":"10 ether"})
    address = parImpar[0].address
    contrato = parImpar.at(address)

    jogador = accounts[1]
    valor_jogador = b'3'
    nonce_jogador = createNonce(b'nonce2')
    commit_jogador = doCommit(nonce_jogador,valor_jogador)
    
    contrato.entraJogo(commit_jogador,{"from":jogador,'value':"20 ether"})
    contrato.jogadorRevela(b'1',nonce_jogador,{"from":jogador})
    
    for _ in range(20):
        contrato.pagaVencedor()


