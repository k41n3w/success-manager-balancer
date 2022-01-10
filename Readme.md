# Balanceador de Gerentes de Sucesso e Clientes
[![Ruby](https://github.com/k41n3w/success-manager-balancer/actions/workflows/ruby.yml/badge.svg)](https://github.com/k41n3w/success-manager-balancer/actions/workflows/ruby.yml)

Exercício de Ruby onde é preciso fazer o balanceamento entre os Gerente de Sucesso (CSs) x Clientes.

---

## Descrição do problema:

Os CSs são os Gerentes de Sucesso, são responsáveis pelo acompanhamento estratégico dos clientes.

Dependendo do tamanho do cliente - aqui nos referimos ao tamanho da empresa - nós temos que colocar CSs mais experientes para atendê-los.

Um CS pode atender mais de um cliente e além disso os CSs também podem sair de férias, tirar folga, ou mesmo ficarem doentes. É preciso levar esses critérios em conta na hora de rodar a distribuição.

Dado este cenário, o sistema distribui os clientes com os CSs de capacidade de atendimento mais próxima (maior) ao tamanho do cliente.

### Exemplo

Se temos 6 clientes com os seguintes níveis: 20, 30, 35, 40, 60, 80 e dois CSs de níveis 50 e 100, o sistema deveria distribui-los da seguinte forma:

- 20, 30, 35, 40 para o CS de nível 50
- 60 e 80 para o CS de nível 100

Sendo `n` o número de CSs, `m` o númro de clientes e `t` o número de abstenções de CSs, calcular quais clientes serão atendidos por quais CSs de acordo com as regras apresentadas.


### Premissas

- Todos os CSs têm níveis diferentes
- Não há limite de clientes por CS
- Clientes podem ficar sem ser atendido
- Clientes podem ter o mesmo tamanho
- 0 < n < 1.000
- 0 < m < 1.000.000
- 0 < id do cs < 1.000
- 0 < id do cliente < 1.000.000
- 0 < nível do cs < 10.000
- 0 < tamanho do cliente < 100.000
- Valor máximo de t = n/2 arredondado para baixo

## Input

A classe recebe 3 parâmetros:

- id e nivel da experiencia do CS
- id e nivel de experiência dos Clientes
- ids dos CustomerSuccess indisponíveis


## Output

O resultado esperado deve ser o id do CS que atende mais clientes. Com esse valor a empresa poderá fazer um plano de ação para contratar mais CS's de um nível aproximado.

Em caso de empate retornar `0`.

### Exemplo

No input de exemplo, CS's 2 e 4 estão de folga, sendo assim o CS 1 vai atender os clientes de tamanho até 60 (clientes 2, 4, 5, 6), enquanto o CS 3 vai atender os clientes 1 e 3.

Para este exemplo o retorno deve ser `1`, que é o id do CS que atende 4 clientes:

```ruby
1
```
