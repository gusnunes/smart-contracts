#!/usr/bin/python3

from brownie import *
import hashlib
from random import choice

def createNonce(s):
    n = hashlib.sha256()
    n.update(s)
    return n.digest()

def doCommit(n,v):
    c = hashlib.sha256()
    c.update(n)
    c.update(v)
    return c.digest()

# subornados -> enderecos do indice '1' até indice 'qtd_participante+1'
def add_bribe_subornados(dono,contrato,qtd_participantes):
    for idx in range(1,qtd_participantes+1):
        contrato.adicionaSubornado(accounts[idx],{"from":dono})

def revela_votos(contrato,participantes,qtd_participantes):
    for idx in range(1,qtd_participantes+1):
        nonce,value = participantes[idx-1]
        contrato.revelaVoto(nonce,value,{"from":accounts[idx]})

def coleta_votos(contrato,opcoes,qtd_participantes):
    # informacao de cada participantes: nonce e value
    participantes = []
    
    for idx in range(1,qtd_participantes+1):
        string = "nonce" + str(idx)
        nonce = createNonce(string.encode())
        
        opcao = choice(opcoes)
        value = (opcao).to_bytes(1, byteorder="little", signed=False)

        commit = doCommit(nonce,value)
        contrato.coletaVoto(commit,{"from":accounts[idx]})

        participantes.append((nonce,value))
    
    return participantes

# participantes -> enderecos do indice '1' até indice 'qtd_participante+1'
def add_schelling_participantes(dono,contrato,qtd_participantes):
    for idx in range(1,qtd_participantes+1):
        contrato.adicionaParticipante(accounts[idx],{"from":dono})

def main():
    # sim ou nao
    # cada participante escolhe randomicamente
    opcoes = [1,0]

    qtd_participantes = 5
    qtd_subornados = qtd_participantes - 2
    
    # enderecos dos donos
    schelling_dono = accounts[0]
    bribe_dono = accounts[9]

    # deploy da biblioteca de commit
    SimpleCommit.deploy({'from':schelling_dono})
    
    # deploy do SchellingCoin
    simpleSchellingCoin.deploy(qtd_participantes,{"from":schelling_dono, "value":"10 ether"})
    schelling_endereco = simpleSchellingCoin[0].address
    schelling_contrato = simpleSchellingCoin.at(schelling_endereco)

    add_schelling_participantes(schelling_dono,schelling_contrato,qtd_participantes)

    # deploy do Bribe
    Bribe.deploy(schelling_contrato,qtd_subornados,{"from":bribe_dono, "value":"10 ether"})
    bribe_endereco = Bribe[0].address
    bribe_contrato = Bribe.at(bribe_endereco)

    add_bribe_subornados(bribe_dono,bribe_contrato,qtd_subornados)
    
    participantes = coleta_votos(schelling_contrato,opcoes,qtd_participantes)
    revela_votos(schelling_contrato,participantes,qtd_participantes)
    
    schelling_contrato.pagaVencedores({"from":schelling_dono})
    print("Voto vencedor:", schelling_contrato.getVotoVencedor.call())

    bribe_contrato.pagaSubornados({"from":bribe_dono})

    # imprime o voto de cada participante
    dicionario = {b'\x01':'sim', b'\x00':'nao'}
    votos = [dicionario[value] for _,value in participantes]
    print(votos)