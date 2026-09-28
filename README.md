# Auditoria da Conta Root - Linux

Script Bash para realizar o levantamento da situação da conta `root` em servidores Linux.

O objetivo é **identificar se o acesso root está habilitado, verificar configurações de SSH, levantar histórico de acessos e identificar possíveis origens de acesso**, sem realizar alterações no servidor.

---

## Objetivo

Este script foi desenvolvido para apoiar atividades de:

* Inventário de acessos privilegiados;
* Identificação de servidores com `root` habilitado;
* Identificação de acesso `root` via SSH;
* Levantamento da origem dos acessos SSH do `root`;
* Verificação do histórico de login do `root`;
* Identificação de usuários com UID `0`;
* Verificação de chaves SSH associadas ao `root`;
* Coleta de informações para posterior solicitação de autorização para rotação da senha do `root`.

> **Importante:** o script é somente de consulta. Nenhuma senha, configuração, usuário ou serviço é alterado.

---

## Informações coletadas

O script realiza 9 etapas de coleta.

### 1. Status da conta ROOT

Executa:

```bash
sudo passwd -S root
```

Permite identificar se a senha da conta `root` está:

* `P` - senha definida;
* `L` - senha bloqueada;
* `NP` - nenhuma senha definida.

Exemplo:

```text
root P 09/28/2026 0 99999 7 -1
```

Nesse exemplo, a senha está definida e não está bloqueada.

---

### 2. Validade e expiração da senha

Executa:

```bash
sudo chage -l root
```

Coleta informações como:

* Data da última alteração da senha;
* Data de expiração;
* Período mínimo;
* Período máximo;
* Período de inatividade;
* Expiração da conta.

---

### 3. Acesso ROOT via SSH

Verifica:

```text
PermitRootLogin
```

Em:

```text
/etc/ssh/sshd_config
/etc/ssh/sshd_config.d/
```

Também tenta obter a configuração efetiva através de:

```bash
sudo sshd -T
```

Exemplos:

```text
permitrootlogin yes
```

Indica que o login SSH direto como `root` está permitido.

```text
permitrootlogin no
```

Indica que o login SSH direto como `root` está bloqueado.

```text
permitrootlogin prohibit-password
```

Indica que o login por senha está proibido, mas autenticação por chave pode ser permitida.

---

### 4. Histórico de login do ROOT

Utiliza:

```bash
lastlog -u root
```

e:

```bash
last -a root
```

O objetivo é identificar:

* Último login;
* Data e hora;
* Terminal;
* Origem do acesso, quando disponível;
* Histórico de acessos registrados.

---

### 5. Origem dos acessos SSH do ROOT

O script identifica automaticamente o arquivo de autenticação:

```text
/var/log/auth.log
```

ou:

```text
/var/log/secure
```

Depois procura registros relacionados ao `root`.

Exemplo:

```text
Accepted password for root from 10.10.10.20
```

ou:

```text
Accepted publickey for root from 10.10.10.30
```

Essas informações permitem identificar a **origem do acesso**, principalmente o endereço IP.

---

### 6. Utilização de SUDO

São pesquisados registros de utilização do `sudo` no log de autenticação.

Exemplo:

```text
sudo: usuario : TTY=pts/0 ; PWD=/home/usuario ; USER=root ; COMMAND=/bin/bash
```

Esse tipo de registro permite identificar um usuário que obteve privilégios de `root` através do `sudo`.

---

### 7. Usuários com UID 0

O script verifica:

```bash
/etc/passwd
```

procurando usuários com:

```text
UID = 0
```

O usuário padrão é:

```text
root
```

Porém, podem existir contas adicionais com UID `0`.

Exemplo:

```text
root
adminroot
```

Uma conta com UID `0` possui privilégios equivalentes ao `root`, independentemente do nome utilizado.

---

### 8. Chaves SSH do ROOT

O script verifica:

```text
/root/.ssh/authorized_keys
```

Caso o arquivo exista, informa:

* Se existem chaves configuradas;
* Quantidade de chaves;
* Tipos de chave encontrados.

O conteúdo das chaves **não é exibido** pelo script.

Isso ajuda a identificar se existe possibilidade de acesso SSH ao `root` utilizando autenticação por chave.

---

### 9. Resumo

Ao final, o script apresenta um resumo contendo:

* Servidor;
* Status da senha do `root`;
* Configuração de SSH;
* Último login;
* Usuários com UID `0`;
* Existência de chave SSH do `root`;
* Localização do relatório.

---

# Requisitos

O servidor deve possuir:

* Linux;
* Bash;
* `sudo`;
* `passwd`;
* `chage`;
* `last`;
* `lastlog`;
* `grep`;
* `awk`.

Para executar algumas verificações, o usuário precisa possuir privilégios `sudo`.

---

# Como utilizar

## 1. Criar o arquivo

Salve o script como:

```text
root_audit.sh
```

---

## 2. Dar permissão de execução

```bash
chmod +x root_audit.sh
```

---

## 3. Executar

```bash
sudo ./root_audit.sh
```

O script exibirá o progresso no terminal:

```text
[01/9] Verificando status da conta ROOT

[02/9] Verificando validade e expiração da senha ROOT

[03/9] Verificando se ROOT pode acessar via SSH

[04/9] Verificando histórico de login do ROOT

[05/9] Identificando origem dos acessos SSH do ROOT

[06/9] Verificando utilização de SUDO

[07/9] Verificando usuários com UID 0

[08/9] Verificando acesso SSH por chave do ROOT

[09/9] Gerando resumo da situação do ROOT
```

---

# Relatório

Além de exibir as informações no terminal, o script gera automaticamente um arquivo em:

```text
/tmp/root_audit_NOME_DO_SERVIDOR_DATA_HORA.txt
```

Exemplo:

```text
/tmp/root_audit_MBCD-TIE-EAS_2026-09-28_11-30-00.txt
```

O arquivo pode ser utilizado como evidência da coleta realizada no servidor.

---

# Exemplo de resultado

Um servidor com root habilitado pode apresentar:

```text
Status da senha:
root P 09/28/2026 0 99999 7 -1

SSH:
permitrootlogin yes

Último login:
root     pts/0        10.10.10.20

Usuários UID 0:
root

Chave SSH do ROOT:
SIM - /root/.ssh/authorized_keys encontrado
```

Nesse cenário, o servidor deve ser analisado para identificar:

1. Quem utiliza o acesso `root`;
2. De qual origem/IP ocorre o acesso;
3. Se o acesso é realizado por senha ou chave;
4. Se o acesso ainda é necessário;
5. Quem é o responsável pelo acesso;
6. Se existe autorização para rotação da senha.

---

# Interpretação para o levantamento

Para cada servidor, recomenda-se registrar pelo menos:

| Informação               | Resultado            |
| ------------------------ | -------------------- |
| Servidor                 | Nome do servidor     |
| Root habilitado          | SIM/NÃO              |
| Senha definida           | SIM/NÃO              |
| Senha bloqueada          | SIM/NÃO              |
| Root via SSH             | SIM/NÃO              |
| Último acesso root       | Data/hora            |
| Origem do acesso         | IP/hostname          |
| Método de acesso         | Senha/Chave/Sudo     |
| Usuários UID 0           | Usuários encontrados |
| Chave SSH root           | SIM/NÃO              |
| Necessidade do acesso    | A validar            |
| Autorização para rotação | Pendente/Aprovada    |

---

# Segurança

O script não executa comandos para:

* Alterar senha;
* Bloquear o `root`;
* Desbloquear o `root`;
* Alterar `sshd_config`;
* Remover usuários;
* Alterar `sudoers`;
* Remover chaves SSH;
* Reiniciar serviços.

Ele realiza apenas **coleta de informações**.

O relatório gerado deve ser tratado como informação sensível, pois pode conter nomes de usuários, endereços IP e registros de autenticação.

---

# Fluxo recomendado

```text
              ┌──────────────────────┐
              │ Executar root_audit   │
              └──────────┬───────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │ Root está habilitado?│
              └──────────┬───────────┘
                         │
                  ┌──────┴──────┐
                  │             │
                 SIM            NÃO
                  │             │
                  ▼             ▼
        ┌────────────────┐   Registrar
        │ Identificar    │   resultado
        │ origem/acesso  │
        └───────┬────────┘
                │
                ▼
        ┌────────────────┐
        │ Validar se o   │
        │ acesso é usado │
        └───────┬────────┘
                │
                ▼
        ┌────────────────┐
        │ Solicitar      │
        │ autorização    │
        │ para rotação   │
        └────────────────┘
```

---

## Limitações

A ausência de registros no log não significa necessariamente que nunca houve acesso.

Dependendo da distribuição Linux, configuração de `rsyslog`, `journald`, rotação de logs ou retenção centralizada, registros antigos podem não estar disponíveis localmente.

Por isso, o resultado deve ser analisado juntamente com os mecanismos centralizados de logs, quando existentes.

---

## Uso no processo de levantamento

O script deve ser utilizado como **primeira etapa do levantamento de acessos privilegiados**.

Após a coleta, os resultados podem ser consolidados em uma planilha contendo todos os servidores e, para cada servidor, a situação da conta `root`, origem dos acessos e necessidade de autorização para rotação da senha.
