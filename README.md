Introdução
----------

[![](media/logotipo-NCLuaSOAP-pequeno.png)](media/logotipo-NCLuaSOAP-pequeno.png)O NCLua SOAP é um módulo escrito totalmente em Lua, que permite o acesso a Web Services SOAP a partir de aplicações de TV Digital. O módulo está em fase beta e implementa as versões 1.1 e 1.2 do protocolo SOAP.


O projeto facilita a convergência entre Web e TV, permitindo o consumo de diferentes serviços, construídos em diferentes linguagens.


Justificativa
-------------

Consumir Web Service SOAP a partir de uma aplicação NCL/Lua para TV Digital tem sido um desejo de muitos, como tenho acompanhado nos fóruns que participo. Os Web Services são bastante utilizados para integração de aplicações, heterogêneas ou não, pois utilizam um protocolo padronizado pela W3C, baseado em XML e trafegando normalmente por HTTP, sem sofrer problemas com firewalls (pelo bloqueio de portas). Eles permitem a criação de aplicações distribuídas, retirando das aplicações clientes, parte da carga de processamento.

Na área de aplicações de TV Digital, os Web Services permitem ainda, a integração de tais aplicações com serviços já implementados, sem necessidade de retrabalho, viabilizando uma maior convergênica entre TV Digital e Web. Existe um projeto chamado [LuaSoap](http://www.keplerproject.org/luasoap/) com objetivo semelhante, porém, o mesmo depende de bibliotecas escritas em C/C++, e utiliza, de forma direta, as funções da [LuaSocket](http://luasocket.luaforge.net), também escrita em C.

Como estas bibliotecas não fazem parte das normas do Sistema Brasileiro de TV Digital (SBTVD) e por serem bibliotecas compiladas, não se pode chamar suas funções diretamente a partir de uma aplicação interativa. Por questões de segurança, não é previsto o uso de bibliotecas em código nativo (como uma compilada em C) enviadas por broadcast. Além disto, tal biblioteca pode não funcionar em todos os receptores de TV Digital compatíveis com o Ginga, o middleware do SBTVD, devido diferenças de arquitetura de hardware e sistema operacional.

Sabe-se que ao menos na versão 0.11.2 da implementação de referência do Ginga, disponível no Portal do Software Público, está sendo utilizada a biblioteca LuaSocket para implementar o módulo tcp, (definido em norma ABNT) para aplicações NCLua. No entanto, esta biblioteca é apenas usada como camada subjacente ao módulo tcp, sendo que suas funções não devem ser utilizadas pelas aplicações desenvolvidas. Deve-se considerar apenas a interface disponibilizada pelo módulo tcp (prevista em norma e existente em qualquer receptor). Com isto, devido ao meu trabalho de mestrado e necessidade de tal recurso, desenvolvi o NCLua SOAP, um módulo escrito completamente em Lua, para ser utilizado em aplicações NCLua para TV Digital.


Outros módulos utilizados (já inclusos no projeto)
--------------------------------------------------

O módulo utiliza a biblioteca [LuaXML](https://github.com/manoelcampos/LuaXML) (que foi adaptada para Lua 5) e o módulo [NCLua HTTP](https://github.com/manoelcampos/NCLuaHTTP) desenvolvido por mim. 


Pré-Requisitos
--------------

É recomendado a utilização do [Ginga Virtual STB 0.11.2 rev 23 ou superior](http://www.gingancl.org.br). A versão anterior do Ginga VSTB possuia algumas dificuldades para acesso à rede a partir da VM, normalmente necessitando de configurações na interface de rede da mesma. Antes de usar o NCLua SOAP na VM, verifique se ela está acessando a rede local/internet (usando ping, telnet, wget, curl ou qualquer comando similar). Para isto, fundamentalmente, na tela inicial da VM deve ser exibido o IP da mesma. Caso não esteja conseguindo acesso à rede, tente alterar o modo da interface de rede da VM de bridge para NAT ou vice-versa (é necessário reiniciar a VM após tal alteração).

Artigo Publicado
----------------

O Artigo NCLua SOAP: Acesso à Web Services em Aplicações de TVDi foi publicado no Workshop de Computação Aplicada em Governo Eletrônico (WCGE 2011), [disponível aqui](https://www4.serpro.gov.br/wcge2011/artigos-selecionados). Caso o link esteja quebrado, o artigo também está disponível [aqui](artigos-tutoriais/Artigo-NCLuaSOAP-Acesso-a-Web-Services-em-aplicacoes-de-TVDi-2011.pdf). Para trabalhos acadêmicos e projetos que utilizem o NCLua SOAP, favor referenciar o artigo publicado. Para referenciar o artigo em documentos Latex, utilize o código bibtex [deste link](artigos-tutoriais/ncluasoap.bib).

Documentação
------------

A documentação da biblioteca foi gerada com LuaDoc e está [disponível para consulta online aqui](http://manoelcampos.github.io/NCLuaSOAP/doc/).

Utilizando o NCLua SOAP
-----------------------

Para usar o NCLua SOAP, basta adicionar as linhas abaixo ao seu script lua:

```lua
--Adiciona o diretório lib (onde estão os arquivos do NCLua SOAP) ao path de bibliotecas,
--para que a aplicação encontre os módulos disponibilizados
package.path = package.path .. ';lib/?.lua'
require "ncluasoap"
```

A função principal do módulo é a call (ncluasoap.call), que gera e envia um requisição SOAP e obtém o XML de retorno, que é convertido para uma tabela lua (com o módulo LuaXML) para facilitar o acesso aos dados de retorno da chamada do método remoto. O principal parâmetro da função ncluasoap.call é o msgTable, que deve ser uma tabela lua contendo os dados para acesso ao método no Web Service. Na documentação e nos exemplos, é explicado com mais detalhes como isso funciona.Veja a seguir a estrutura que deve ter esse parâmetro:

```lua
msgTable = {
  address = "url do serviço (não é o endereço do wsdl)",
  namespace = "namespace, exatamente como informado no wsdl",
  operationName = "método remoto que deseja-se acessar",

  --Parâmetros de entrada, como definidos no WSDL
  params = {
      paramName1=value1,
      paramName2=value2,
      paramNameN=valueN
  }
}
```

A função call ainda aceita uma função de callback, que é explicada em mais detalhes na documentação do NCLua SOAP e principalmente no módulo http (motivo da necessidade de uso de tais funções).


Exemplos
--------

Foram disponibilizadas algumas aplicações de exemplo, que consomem Web Services variados. Para testar os diversos Web Services usados na segunda aplicação de exemplo, basta descomentar uma chamada a ncluasoap.call, dentro da função handler do arquivo exemplo2.lua, comentando o anterior (por motivos de clareza). As aplicações não possuem interface gráfica, logo, todo o resultado é mostrado em mensagens no console. Leia os comentários existentes nos exemplos, pois alguns serviços requerem configurações extras para funcionar (como cadastro/login e senha). Um exemplo completo, mostrando como consumir um Web Service de cotação de moedas, é exibido abaixo.

```lua
---Exemplo simples, mas completo, de uso do NCLua SOAP
package.path = package.path .. ';lib/?.lua'
require "ncluasoap"
---Função para processar a resposta da requisição SOAP enviada ao WS
--@param result Resposta da chamada do método remoto, neste caso, uma string.
--Dependendo do método remoto chamado, o result pode ser de um tipo estruturado,
--como um vetor ou struct
local function getResponse(resul)
  --O nome do elemento que contém o retorno é obtido no WSDL ou no XML de retorno
  print("Cotação do Dolar em Reais:", result)
end

--Cria uma table contendo os dados para envio da requisição SOAP ao WS
local msgTable = {
  address = "http://www.webservicex.net/CurrencyConvertor.asmx",
  --Namespace exatamente como especificado no WSDL, neste caso, terminando com /
  namespace = "http://www.webserviceX.NET/",
  operationName = "ConversionRate",
  params = {
    FromCurrency = "USD", --Dólar
    ToCurrency = "BRL" --Real
  }
}

--Executa o método remoto, definido dentro da msgTable,
--gerando uma requisição SOAP, enviando ao WS e obtendo o resultado.
--getResponse é uma função de callback que será executada
--automaticamente, assim que a resposta da chamada remota for obtida.
ncluasoap.call(msgTable, getResponse)

--Esta linha é executada automaticamente após a chamada de ncluasoap.call
--A chamada a ncluasoap.call retorna imediatamente, pois é uma chamada
--assíncrona, devido a particularidades do módulo TCP de NCLua.
--Assim, NÃO é possível obter o retorna do método remoto
--fazendo algo como retorno = ncluasoap.call(msgTable).
--Tal instrução não funciona.
print("---------------------------Chamou ncluasoap.call")
```

Após a chamada da função ncluasoap.call, quando o método remoto retornar um resultado, a função getResponse será automaticamente chamada, recebendo a resposta do método remoto como parâmetro. Observe que dentro da função _getResponse_, o valor retornado pelo WS é obtido por meio do acesso ao parâmetro _result_.

A chamada a ncluasoap.call possui ainda um terceiro parâmetro opcional, que indica a versão do protocolo SOAP que deve ser utilizada na comunicação com o WS. Se omitido, é assumido o valor "1.2". Alguns Web Services suportam tanto a versão 1.1 como 1.2 do SOAP (como os Web Services ASP.NET, as páginas asmx). Outros suportam apenas a 1.1 (como alguns Web Services em PHP), e podem haver outros que só suportem a versão 1.2. Assim, o desenvolvedor precisa atentar à versão do SOAP suportada pelo WS, informação que normalmente pode ser encontrada na página do Web Service (a mesma página informada na tabela passada à função call do módulo ncluasoap).

**OBSERVAÇÃO**: O _namespace_ deve ser exatamente como definido no documento WSDL. Se o mesmo terminar com barra, deve ser incluída a barra. Se não terminar, não deve-se incluir. Alguns serviços podem não funcionar (exibindo uma mensagem de erro indicando o correto namespace a ser utilizado) caso não esteja exatamente como apresentado no WSDL.


Tutoriais
---------

[Criando um Web Service PHP com NuSoap e acessando-o com NCLua Soap - por Johnny Moreira Gomes (UFJF)](http://www.ufjf.br/lapic/files/2010/05/TutorialNuSoapNCLuaSoap.pdf). Caso o link esteja quebrado, o tutorial pode ser acessado [aqui](artigos-tutoriais/tutorial-nusoap-ncluasoap.pdf).


FAQ
---
	
1. **Porque ocorre o erro "HTTP 415: Media Unsupported"?** Este erro pode ocorrer devido à versão da requisição SOAP enviada não ser suportada pelo Web Service. Verifique a documentação da função call do módulo NCLua SOAP para saber como especificar a versão do SOAP a ser utilizada pelo módulo. Se não souber qual versão do protocolo SOAP o Web Service reconhece, teste os valores listados na documentação da função call do módulo.	
2. **Porque ocorre o erro "unprotected error in call to Lua API (tcp.lua:xx: /usr/local/lib/lua/5.1/tcp_event.lua:xx: assertion failed!)"?** Este erro pode ocorrer devido a aplicação, rodando no Ginga Virtual STB, não ter acesso à Internet/LAN. Tal problema era comum na versão anterior a 0.11.2 do Ginga Virtual STB. Verifique a seção de pré-requisitos para mais informações.

Fórum de Discussão
------------------

Para tirar dúvidas, relatar bugs, propor melhorias e quaisquer outros assuntos relacionados a Web Services em aplicações NCLua para TV Digital, acesse o [Fórum NCLua SOAP no Google Groups](http://groups.google.com/group/ncluasoap).


Aviso
-----

O módulo implementa as versões 1.1 e 1.2 do protocolo SOAP, e está em fase beta, podendo conter bugs e inconsistências com o padrão. Assim, use por sua conta e risco! Dúvidas, críticas, sugestões e, principalmente, relatos de problemas com algum WebService, são bem vindos e devem ser enviados pelo Fórum mostrado acima.



Licença
-------

O projeto é licenciado sob a [Creative Commons Atribuição-NãoComercial-CompartilhaIgual 2.5 Brasil (CC BY-NC-SA 2.5 BR)](http://creativecommons.org/licenses/by-nc-sa/2.5/br/)
