```bash
#!/bin/bash

# ============================================================
# AUDITORIA DA CONTA ROOT - LINUX
# Somente coleta de informações
# NÃO realiza alterações
# Autor: Felipe Giló
# Data: 28/09/2026
# ============================================================

HOST=$(hostname -f 2>/dev/null || hostname)
DATE=$(date '+%Y-%m-%d_%H-%M-%S')
OUTPUT="/tmp/root_audit_${HOST}_${DATE}.txt"

# Detectar log de autenticação
if [ -f /var/log/auth.log ]; then
    AUTH_LOG="/var/log/auth.log"
elif [ -f /var/log/secure ]; then
    AUTH_LOG="/var/log/secure"
else
    AUTH_LOG=""
fi

# Enviar saída para tela e arquivo
exec > >(tee -a "$OUTPUT") 2>&1

STEP=0
TOTAL=9

step() {
    STEP=$((STEP + 1))

    echo
    echo "============================================================"
    echo "[$(printf '%02d' "$STEP")/$TOTAL] $1"
    echo "============================================================"
}

echo "============================================================"
echo "             AUDITORIA DA CONTA ROOT"
echo "============================================================"
echo "Servidor : $HOST"
echo "Data     : $(date)"
echo "Usuário  : $(whoami)"
echo "SO       : $(grep '^PRETTY_NAME=' /etc/os-release 2>/dev/null | cut -d= -f2- | tr -d '"')"
echo "Kernel   : $(uname -r)"
echo "Arquivo  : $OUTPUT"
echo "============================================================"


# ============================================================
# 01 - STATUS DA CONTA ROOT
# ============================================================

step "Verificando status da conta ROOT"

sudo passwd -S root 2>/dev/null


# ============================================================
# 02 - INFORMAÇÕES DA SENHA / EXPIRAÇÃO
# ============================================================

step "Verificando validade e expiração da senha ROOT"

sudo chage -l root 2>/dev/null


# ============================================================
# 03 - SSH ROOT
# ============================================================

step "Verificando se ROOT pode acessar via SSH"

echo "--- Configuração PermitRootLogin ---"

sudo grep -RniE '^[[:space:]]*PermitRootLogin' \
    /etc/ssh/sshd_config \
    /etc/ssh/sshd_config.d/ 2>/dev/null

echo
echo "--- Configuração efetiva do SSH ---"

if command -v sshd >/dev/null 2>&1; then
    sudo sshd -T 2>/dev/null | grep -i '^permitrootlogin'
fi


# ============================================================
# 04 - ÚLTIMOS LOGINS ROOT
# ============================================================

step "Verificando histórico de login do ROOT"

echo "--- lastlog ---"

lastlog -u root 2>/dev/null

echo
echo "--- últimos acessos registrados ---"

last -a root 2>/dev/null | head -30


# ============================================================
# 05 - ACESSOS SSH DO ROOT
# ============================================================

step "Identificando origem dos acessos SSH do ROOT"

if [ -n "$AUTH_LOG" ]; then

    echo "Arquivo analisado: $AUTH_LOG"

    echo
    echo "--- Logins SSH aceitos como ROOT ---"

    sudo grep -Ei \
        'sshd.*Accepted.*root' \
        "$AUTH_LOG" |
        tail -100

    echo
    echo "--- Tentativas de acesso como ROOT ---"

    sudo grep -Ei \
        'sshd.*(root|invalid user root)' \
        "$AUTH_LOG" |
        tail -100

else

    echo "Arquivo de autenticação não encontrado."

fi


# ============================================================
# 06 - SUDO RELACIONADO AO ROOT
# ============================================================

step "Verificando utilização de SUDO"

if [ -n "$AUTH_LOG" ]; then

    sudo grep -Ei 'sudo:' "$AUTH_LOG" | tail -100

else

    echo "Arquivo de autenticação não encontrado."

fi


# ============================================================
# 07 - USUÁRIOS COM UID 0
# ============================================================

step "Verificando usuários com UID 0"

sudo awk -F: '$3 == 0 {
    print "Usuário: "$1
    print "UID    : "$3
    print "HOME   : "$6
    print "SHELL  : "$7
    print "----------------------------------------"
}' /etc/passwd


# ============================================================
# 08 - CHAVES SSH DO ROOT
# ============================================================

step "Verificando acesso SSH por chave do ROOT"

if [ -f /root/.ssh/authorized_keys ]; then

    echo "Arquivo encontrado:"
    echo "/root/.ssh/authorized_keys"

    echo
    echo "Quantidade de chaves:"
    sudo grep -cEv '^[[:space:]]*#|^[[:space:]]*$' \
        /root/.ssh/authorized_keys

    echo
    echo "Tipos de chave encontrados:"

    sudo awk '
    !/^[[:space:]]*#/ && NF >= 2 {
        print $1
    }' /root/.ssh/authorized_keys |
    sort |
    uniq -c

else

    echo "Nenhum /root/.ssh/authorized_keys encontrado."

fi


# ============================================================
# 09 - RESUMO
# ============================================================

step "Gerando resumo da situação do ROOT"

echo
echo "============================================================"
echo "                     RESUMO ROOT"
echo "============================================================"

echo
echo "Servidor:"
echo "$HOST"

echo
echo "Status da senha:"
sudo passwd -S root 2>/dev/null

echo
echo "SSH:"
if command -v sshd >/dev/null 2>&1; then
    sudo sshd -T 2>/dev/null |
        grep -i '^permitrootlogin'
else
    sudo grep -RhiE '^[[:space:]]*PermitRootLogin' \
        /etc/ssh/sshd_config \
        /etc/ssh/sshd_config.d/ 2>/dev/null
fi

echo
echo "Último login:"
lastlog -u root 2>/dev/null

echo
echo "Usuários UID 0:"
sudo awk -F: '$3 == 0 {print $1}' /etc/passwd

echo
echo "Chave SSH do ROOT:"
if [ -f /root/.ssh/authorized_keys ]; then
    echo "SIM - /root/.ssh/authorized_keys encontrado"
else
    echo "NÃO - arquivo não encontrado"
fi

echo
echo "============================================================"
echo "                 AUDITORIA FINALIZADA"
echo "============================================================"
echo "Servidor : $HOST"
echo "Relatório: $OUTPUT"
echo "Data     : $(date)"
echo "============================================================"
```
