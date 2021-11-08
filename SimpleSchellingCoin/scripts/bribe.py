#!/usr/bin/python3

from brownie import *

def main():
    # endereco do dono
    dono = accounts[0]

    contrato_schelling = input()
    
    # deploy do SchellingCoin
    Bribe.deploy(contrato_schelling,{"from":dono, "value":"10 ether"}) # LEMBRAR DE COLOCAR 10 ETHER AQUI DEPOIS
    address = Bribe[0].address
    contrato = Bribe.at(address)

    print(contrato.teste({"from":dono}))