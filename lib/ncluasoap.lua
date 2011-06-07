---Módulo NCLua SOAP v0.5.6.6: Módulo desenvolvido inteiramente em Lua, para acesso a 
--WebServices SOAP em aplicações de TV Digital.<p/>
--Utiliza o módulo LuaXML, disponível em <a href="http://lua-users.org/wiki/LuaXml">http://lua-users.org/wiki/LuaXml</a>, 
--que foi adaptado para Lua 5.x e adicionado parâmetro parseAttributes
--ao método xmlParser.parse para indicar se os atributos das tags
--devem ser processados ou não. <p/>
--Licença: <a href="http://creativecommons.org/licenses/by-nc-sa/2.5/br/">http://creativecommons.org/licenses/by-nc-sa/2.5/br/</a>
--@author Manoel Campos da Silva Filho - <a href="http://manoelcampos.com">http://manoelcampos.com</a> 
--@class module

--http://www.xml.com/pub/a/2000/11/29/schemas/part1.html?page=8
--http://www.developerfusion.com/article/3720/understanding-xml-namespaces/5/
--http://www.quackit.com/xml/tutorial/xml_default_namespace.cfm

require "util"
require "tcp"
require "http"
dofile("lib/LuaXML/xml.lua")
dofile("lib/LuaXML/handler.lua")

local _G, util, tcp, http, print, string, table, pairs, 
      simpleTreeHandler, xmlParser, type, tostring, error
      = 
      _G, util, tcp, http, print, string, table, pairs,
      simpleTreeHandler, xmlParser, type, tostring, error

module "ncluasoap"

local userAgent = "ncluasoap/0.5.6.6"

---Converte uma tabela lua para uma string que representa um trecho de código XML
--@param tb Tabela a ser convertida
--@param level Apenas usado internamente, quando a função
--é chamada recursivamente, para imprimir espaços e 
--representar os níveis dentro da tabela.
--@param elevateAnonymousSubTables Se igual a true, quando encontrada uma sub-tabela sem nome dentro da tabela
--(tendo sido definida apenas como {chave1 = valor1, chave2 = valor2, chaveN = valorN}
--ao invés de nomeSubTabela = {chave1 = valor1, chave2 = valor2, chaveN = valorN})
--os elementos da sub-tabela serão consideradas como se estivessem diretamento dentro da tabela 
--a qual a sub-tabela pertence, e não que estejam dentro da sub-tabela. 
--Tais sub-tabelas não tem um nome para a chave, e sim um índice definido
--automaticamente pelo compilador Lua. O parâmetro é opcional e seu valor default é false.
--O uso do valor true é útil quando tem-se sub-tabelas contendo apenas um campo,
--onde colocou-se tal campo dentro da sub-tabela sem nome, apenas para que, ao ser processada a tabela
--principal, os campos sejam acessados na ordem em que foram definidos, e não em ordem
--arbitrária definida pela função pairs (usada internamente nesta função).
--A ordem do processamento dos campos de uma tabela é importante no caso do
--processamento da tabela de parâmetros a serem passados a um WebService,
--pois WSs PHP feitos como a biblioteca NuSOAP, não 
--verificam o nome dos parâmetros, e sim a ordem em que são passados.
--Assim, o comportamento padrão de acesso aos elementos de uma tabela
--não garante que os campos serão acessados na mesma ordem em que
--foram definidos, podendo fazer com que sejam passados os valores
--trocados para o WS sendo acessado. 
--@return Retorna a string com as tags XML geradas
--a partir dos itens da tabela
--@param tableName Nome da variável table sendo passada para a função. 
--Este parâmetro é opcional e seu valor é utilizado apenas quando
--é passada uma table em formato de um vetor (array) onde 
--só existem índices, não existindo chaves nomeadas (como ocorre em um registro/struct).
--Assim, para cada posição no vetor, será gerada uma tag com o nome do mesmo,
--contendo os dados de cada posição. Isto é utilizado
--quando o método no Web Service a ser chamado possuir um vetor como parâmetro.
--Logo, se existir um parâmetro, no método do WS, 
--de nome vet e do tipo array, a função tableToXml gerará
--um código XML como <vet>valor1</vet><vet>valor2</vet><vet>valorN</vet>
--para passar tal vetor (table lua) ao método do Web Service.
local function tableToXml(tb, level, elevateAnonymousSubTables, tableName)
  level = level or 1
  local spaces = string.rep(' ', level*2)

  local xmltb = {}
  for k, v in pairs(tb) do
      if type(v) == "table" then
         if type(k) == "number" then
	        --Se o nome da chave da sub-tabela for um número,
	        --é porque esta sub-tabela não possui um nome, tendo sido definida
	        --como {chave1 = valor1, chave2 = valor2, chaveN = valorN}
	        --ao invés de nomeSubTabela = {chave1 = valor1, chave2 = valor2, chaveN = valorN}.
	        --Então, se é pra elevar esta sub-tabela anônima, processa seus campos como
	        --se estivessem fora da sub-tabela, como explicado na documentação desta função.
            if elevateAnonymousSubTables then  
               table.insert(xmltb, spaces..tableToXml(v))
            else
               table.insert(xmltb, 
                 spaces..'<'..tableName..'>\n'..tableToXml(v)..
                 '\n'..spaces..'</'..tableName..'>') 
            end
         else --se o elemento é uma tabela e sua chave tem um nome definido    
            level = level + 1
            --Obtém o nome da primeira chave da sub-tabela v. Se o tipo dela for numérico,
            --considera que a mesma é um array (vetor), assim, para cada elemento existente,
            --será criada uma tag com o nome da table. 
            --Por isto, aqui a função tableToXml é chamada recursivamente,
            --passando um valor para o parâmetro tableName.
            if type(util.getFirstKey(v)) == "number" then --
               table.insert(xmltb, spaces..tableToXml(v, level, false, k))
            else
              --Senão, considera que a table está em formato de struct,
              --logo, possui chaves nomeadas. Desta forma, cria uma tag com o nome da table
              --e inclui seus elementos como sub-tags contendo seus respectivos nomes.
              table.insert(
                 xmltb, 
                 spaces..'<'..k..'>\n'.. tableToXml(v, level)..
                 '\n'..spaces..'</'..k..'>')
            end
         end
      else
         --Se o parâmetro tableName foi informado, é porque a table passada
         --está estruturada como um array (vetor), assim, para cada elemento dela
         --deve ser criada uma tag com o nome da table (tableName)
         if tableName then
            k = tableName
         else
            --Se o elemento não for uma tabela mas o nome da sua chave for um índice numérico,
            --deve-se incluir uma letra qualquer antes do nome da chave, pois alguns
            --WS (como os em PHP) não suportam chaves numéricas no XML.
            --Isto é feito apenas quando a função é chamada para gerar o trecho XML para
            --os parâmetros de entrada do WS, quando elevateAnonymousSubTables é true.
            if type(k) == "number" and elevateAnonymousSubTables then 
               k = "p" .. k --p é o prefixo de param (poderia ser usado qualquer caractere alfabético)
            end
         end
         table.insert(xmltb, spaces..'<'..k..'>'..tostring(v)..'</'..k..'>')
      end
  end
  return table.concat(xmltb, "\n")
end

---Remove qualquer elemento que represente informações
--de definições de tipo da tabela, pois somente
--os dados é que interessam.
--@param xmlTable Table lua gerada a partir de código XML
--@return Retorna a nova tabela sem as chaves de schema
local function removeSchema(xmlTable)
     --Se xmlTable não for uma tabela, é porque
     --o resultado retornado pelo WS é simples
     --(como uma string que já foi extraída do XML de retorno).
     --Assim, não sendo uma tabela, não existem dados de XML Schema
     --anexados ao valor retornado (pois para isso a estrutura
     --precisaria ser composta, ou seja, ser uma tabela para
     --armazenar o valor retornado e o XML Schema).
     if type(xmlTable) ~= "table" then
        return xmlTable
     end

     local tmp = {}
     for k, v in pairs(xmlTable) do
        if type(v) == "table" then
           v = removeSchema(v)
        end
        
        if k ~= "xs:schema" then
           tmp[k] = v
        end
     end
     return tmp
end


---Envia uma requisição SOAP para realizar a chamada de um método remoto vai HTTP
--@param  msgTable Tabela contendo os parâmetros
--da requisição, devendo ter o seguinte formato:<br/>
--msgTable = {<br/>
--&nbsp;&nbsp;&nbsp;address = "URL do serviço (não é o wsdl). Pode-se incluir um número de porta na mesma.",<br/>
--&nbsp;&nbsp;&nbsp;namespace = "namespace, informado no wsdl",<br/>
--&nbsp;&nbsp;&nbsp;operationName = "método remoto que deseja-se acessar",<br/>
--&nbsp;&nbsp;&nbsp;--Parâmetros de entrada. Se não existirem parâmetros de entrada,
--                    o campo deve ser omitido<br/>
--&nbsp;&nbsp;&nbsp;params = {<br/>
--&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;paramName1=value1,<br/>
--&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;paramName2=value2,<br/>
--&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;paramNameN=valueN<br/>
--&nbsp;&nbsp;&nbsp;}<br/>
--&nbsp;}<br/>
--@param  callback Função de callback a ser executada quando
--a resposta da requisição for obtida. A mesma deve possuir
--em sua assinatura, um parâmetro response, que conterá
--o retorno da chamada da função remota.
--@param  soapVersion Versão do protocolo SOAP a ser utilizado.
--Os valores permitidos são 1.1 e 1.2. Se omitido, será usado 1.2
--Alguns WebServices (como os em ASP.NET, de extensão asmx)
--suportam diferentes versões do SOAP (como 1.1 e 1.2),
--mas pode ser que isto não seja verdade para todos os serviços.
--Assim, precisará ser informado qual a versão do protocolo a ser utilizada. 
--@param  port Porta a ser utilizada para a conexão. O padrão é 80, no caso do valor ser omitido.
--A porta também pode ser especificada diretamente na URL (campo address do parâmetro msgTable). 
--Se for indicada uma porta lá e aqui no parâmetro port, a porta da url é que será utilizada e a do parâmetro port será ignorada.
--@param boolean externalXsd Indica se o Web Service utiliza um arquivo externo (xsd) para as definições de tipos (XML Schema Definition).
--O formato da requisição SOAP é dependente disto. A maioria dos Web Services construídos, em diversas linguagens,
--inclui as definições de tipo diretamente no arquivo WSDL. Os Web Services que usam um xsd externo possuem
--uma tag xsd:import em seu WSDL. Enquanto o NCLua SOAP não descobre automaticamente esta informação,
--é necessário que a mesma seja informada pelo desenvolvedor que for usar o módulo.
--Web Services feitos com a ferramenta Netbeans, utilizando a biblioteca JAX-WS (pelo menos em alguma
--de suas versões) faz uso de um xsd externo. Neste caso, este parâmetro externalXsd deve ser true.
--O valor padrão do parâmetro é false. 
--@param httpUser Nome de usuário para realizar autenticação HTTP, em caso de WS que utilizam tal recurso. Parâmetro Opcional.
--@param httpPasswd Senha para realizar autenticação HTTP, em caso de WS que utilizam tal recurso. Parâmetro Opcional.
--@param soapHeader String contendo cabeçalho SOAP a serem enviado na requisição.
--Tal cabeçalho é uma tag contendo valores a serem passados ao Web Service. Opcional.
function call(msgTable, callback, soapVersion, port, externalXsd, httpUser, httpPasswd, soapHeader)
  if soapVersion == nil or soapVersion == "" then
     soapVersion = "1.2"
  end
  
  if soapVersion ~= "1.1" and soapVersion ~= "1.2" then
     error("soapVersion deve ser 1.1 ou 1.2")
  end
    
  --nsPrefix = Namespace Prefix
  local nsPrefix = ""
  if soapVersion == "1.1" then
     nsPrefix = "soap"
  elseif soapVersion == "1.2" then
     nsPrefix = "soap12"
  end

  local xmltb = {}
  
  --SOAP 1.2 message
  --table.insert(xmltb, '')
  table.insert(xmltb, '<?xml version="1.0"?>')
  table.insert(xmltb, '<'..nsPrefix..':Envelope ')
  table.insert(xmltb, ' xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" ')
  table.insert(xmltb, ' xmlns:xsd="http://www.w3.org/2001/XMLSchema" ')
  if soapVersion == "1.1" then
     table.insert(xmltb, 
       ' xmlns:'..nsPrefix..'="http://schemas.xmlsoap.org/soap/envelope/" ')
  elseif soapVersion == "1.2" then
     table.insert(xmltb, 
       ' xmlns:'..nsPrefix..'="http://www.w3.org/2003/05/soap-envelope" ')
  end
  local serviceNsPrefix = ""
  if externalXsd then
     serviceNsPrefix = "ns1"
     table.insert(xmltb, ' xmlns:'..serviceNsPrefix..'="'..msgTable.namespace..'" ')     
  end
  table.insert(xmltb, '>')

  --Se foi passado um cabeçalho SOAP a ser anexado na requisição,
  --anexa tais dados dentro da tag Header
  if soapHeader then
     table.insert(xmltb, '  <'..nsPrefix..':Header>')
     table.insert(xmltb, soapHeader)
     table.insert(xmltb, '  </'..nsPrefix..':Header>')
  end
  
  table.insert(xmltb, '  <'..nsPrefix..':Body>')
  if externalXsd then
    table.insert(xmltb, '    <'..serviceNsPrefix..':'..msgTable.operationName..'>')
  else
    table.insert(xmltb, '    <'..msgTable.operationName..' xmlns="'..msgTable.namespace..'">')
  end
  
  if msgTable.params then
	  --Percorre a lista de parâmetros da mensagem e gera
	  --tags XML para cada item existente na tabela msgTable.params
    --O parâmetro elevateAnonymousSubTables é definido como true para que
    --sub-tabelas de msgTable.params que não tenham nome, 
    --tenham seu único campo processado como se estivesse fora da tabela anônima.
    --Isto permite que os elementos da tabela de parâmetros sejam
    --acessados na mesma ordem em que foram definidas as sub-tabelas
    --anônimas.
    --Considera-se que estas tabelas anônimas, caso existam, terão
    --apenas um campo, pois cada elemento da tabela de parâmetros
    --a serem passados ao WS deve conter apenas um valor simples.
    --O uso de parâmetros com valores compostos não é suportado
    --pelo NCLua SOAP. Veja mais detalhes na função tableToXml.
    --O valor 3 para o parâmetro level é usado apenas para que seja dada a correta
    --identação na inclusão das tags XML referentes aos parâmetros da chamada SOAP.
	  table.insert(xmltb, tableToXml(msgTable.params, 3, true))
  end

  if externalXsd then
    table.insert(xmltb, '    </'..serviceNsPrefix..':'..msgTable.operationName..'>')
  else
    table.insert(xmltb, '    </'..msgTable.operationName..'>')		
  end

  table.insert(xmltb, '  </'..nsPrefix..':Body>')
  table.insert(xmltb, '</'..nsPrefix..':Envelope>')
  
  local xml = table.concat(xmltb, '\n')
  print(xml)
  
  local httpContentType = ''
  if soapVersion == "1.1" then
		 local soapAction, separator = "", ""

 		 if string.sub(msgTable.namespace, #msgTable.namespace) ~= '/' then
		    separator = '/'
		 end 
		 soapAction = msgTable.namespace..separator..msgTable.operationName
     httpContentType = 
       'Content-Type: text/xml; charset=utf-8\n' ..
       'SOAPAction: "'..soapAction..'"'
  elseif soapVersion == "1.2" then
     httpContentType = 'Content-Type: application/soap+xml; charset="utf-8"'
  end
  
  local function getHttpResponse(header, body)
     print(""); print(body)
     local xmlhandler = simpleTreeHandler()
     local xmlparser = xmlParser(xmlhandler)
     xmlparser:parse(body, false)
     local xmlTable = {}

     if nsPrefix ~= "" then
        nsPrefix = nsPrefix .. ":"
     end
     
     if xmlhandler and xmlhandler.root then   
        --Se a resposta não possui o Namespace Prefix correspondente
        --à versão do SOAP utilizada, testa outros padrões de prefixo.
        if xmlhandler.root[nsPrefix.."Envelope"] == nil then
          nsPrefix = ""
          local prefixes = {"soap:", "SOAP-ENV:", "soapenv:", "S:"}
          for k, v in pairs(prefixes) do
             if xmlhandler.root[v.."Envelope"] ~= nil then
                nsPrefix = v
                break
             end
          end
        end
        print("\n\nResponse nsPrefix = "..nsPrefix.."\n\n")
    
    
        local envelope = nsPrefix.."Envelope"
        local bodytag = nsPrefix.."Body"
        --local operationResp = msgTable.operationName.."Response"
        xmlTable = xmlhandler.root[envelope][bodytag]

        --Dentro da tag body haverá uma outra tag
        --que conterá todos os valores retornados pela
        --função remota. O nome padrão desta tag é 
        --MethodNameResponse (nome do método + Response). 
        --Caso o WS retorne um erro, existirá uma tag Fault dentro
        --do body no lugar da resposta esperada.
        --Assim, o código abaixo pega o valor da primeira chave,
        --que contém os dados da resposta da requisição (seja o retorno
        --do método a tag Fault contendo detalhes do erro)
            
        --O uso da função next não funciona para pegar o primeiro elemento. Trava aqui 
        --_, xmlTable = next(xmlTable)
        for k, v in pairs(xmlTable) do
          xmlTable = v
          break
        end
     end
     
     xmlTable = removeSchema(xmlTable)     
     xmlTable = util.simplifyTable(xmlTable)
     if callback then
        callback(xmlTable)
     end
  end

  local url = msgTable.address
            --(url, callback, method, params, userAgent, headers, user, password, port)
  http.request(url, getHttpResponse, "POST", xml, userAgent,   
               httpContentType, httpUser, httpPasswd, port)
end
