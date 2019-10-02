#!/bin/bash

ROUTE_TABLES=("rtb-lalala01" "rtb-lalala02")
SUBNETS=("192.168.47.0/24" "192.168.76.0/24")
NODE01_INSTANCE="i-lalalala1"
NODE02_INSTANCE="i-lalalala2"
EIP="35.255.244.222"
HOSTNAME=$(hostname -s)
AWS="/usr/local/bin/aws"

if [ $HOSTNAME == 'lalala-01' ]; then
    ACTIVE_INSTANCE=$NODE01_INSTANCE
elif [ $HOSTNAME == 'lalala-02' ]; then
    ACTIVE_INSTANCE=$NODE02_INSTANCE
else
    echo "Hostname incorreto!"
    exit 1
fi

case "$1" in
    'start')
        echo "Movendo Elastic IP para a instância $ACTIVE_INSTANCE ($HOSTNAME)"
        $AWS ec2 associate-address --instance-id $ACTIVE_INSTANCE --public-ip $EIP
        status_code=$?
        if [ $status_code -ne 0 ]; then
            echo; echo "Falha ao mover EIP! Return code: $status_code"
            exit 1
        fi
        echo "Movendo rotas para a instância $ACTIVE_INSTANCE ($HOSTNAME)"
        for table in "${ROUTE_TABLES[@]}"; do
            for net in "${SUBNETS[@]}"; do
                $AWS ec2 replace-route --route-table-id $table --destination-cidr-block $net --instance-id $ACTIVE_INSTANCE
                status_code=$?
                if [ $status_code -eq 0 ]; then
                    echo "Tabela: $table Rede: $net Gateway: $ACTIVE_INSTANCE."
                else
                    echo; echo "Falha ao mover rota! Tabela: $table Rede: $net Gateway: $ACTIVE_INSTANCE. Return code: $status_code"
                fi
            done
        done
    ;;
    'stop')
        echo "Nada a ser feito. Script para uso exclusivo do serviço de Cluster."
    ;;
    *)
    echo "ATENÇÃO: Não executar manualmente. Script para uso exclusivo do serviço de Cluster!"
    echo "Uso: $(basename $0) {start | stop}"
    ;;
esac
