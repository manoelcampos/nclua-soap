---Aplicação de linha de comando para PC, para fazer o parser de um arquivo WSDL
--e mostrar dados necessários para montar uma requisição SOAP em uma aplicação de TVD usando a biblioteca NCLua SOAP.
--Assim, a aplicação deve ser executada fora do Ginga, em um computador com o interpretador Lua 5.x ou superior instalado.
--É necessária a biblioteca luasocket, que pode ser intalada via apt-get no Linux, 
--ou via luarocks em qualquer SO. As bibliotecas util e LuaXML, também necessárias, já estão dentro do diretório.
--Pode-se passar a URL do WSDL via linha de comando.
--Licença: <a href="http://creativecommons.org/licenses/by-nc-sa/2.5/br/">http://creativecommons.org/licenses/by-nc-sa/2.5/br/</a>
--@author Manoel Campos da Silva Filho - <a href="http://manoelcampos.com">http://manoelcampos.com</a> 

package.path = package.path .. ';lib/?.lua'

local http = require("socket.http")
require("util")
dofile("lib/LuaXML/xml.lua")
dofile("lib/LuaXML/handler.lua")

local main, osutil, wsdl = {}, {}, {nsPrefix = ""}

-- -----------------------------------------------------------

---Verifica se o Sistema Operacional é Unix/Linux
--@return Retorna true se o SO for Unix/Linux, senão, retorna false.
function osutil:isUnix()
  --Se existe a variável de ambiente HOME, é um sistema Unix/Linux
  return os.getenv('HOME')
end

---Executa comando de limpar tela, de acordo com o sistema operacional
--em execução.
function osutil:clear()
  if self:isUnix() then
    os.execute("clear")
  else --senão, considera que é Windows
    os.execute("cls")    
  end
end

-- -----------------------------------------------------------

---Realiza o parse do WSDL, convertendo o mesmo para uma tabela Lua
--@param wsdlContent String com o conteúdo do arquivo WSDL
--@return Retorna uma tabela Lua, gerada a partir do conteúdo do WSDL
function wsdl:parseWsdl(wsdlContent)
	 local xmlhandler = simpleTreeHandler()
	 local xmlparser = xmlParser(xmlhandler)
	 xmlparser:parse(wsdlContent, true)

	 if xmlhandler and xmlhandler.root then 
      if xmlhandler.root["wsdl:definitions"] then
        self.nsPrefix = "wsdl:"
      else
        self.nsPrefix = ""
      end    
      --util.printable(xmlhandler.root)
      return xmlhandler.root
   else
      error("Não foi possível converter o WSDL para uma tabela Lua")
   end
end

---Salva o WSDL para um arquivo em disco
--@param wsdlContent String com o conteúdo do arquivo WSDL
--@param fileName Nome do arquivo a ser gerado
function wsdl:saveWsdl(wsdlContent, fileName)
  k = io.open(fileName, "w+")
  k:write(wsdlContent)
  k:close()
end

---Verifica se o WSDL é de um Web Service PHP
--@param wsdlUrl URL do arquivo WSDL
--@return Se a URL for de um WSDL de Web Service em PHP, retorna true, 
--senão, retorna false.
function wsdl:phpWS(wsdlUrl)
   return string.find(wsdlUrl, ".php")
end

---Obtém a versão do SOAP suportada pelo Web Service
--@param wsdlTable Tabela lua gerada a partir do parse do conteúdo do WSDL
--@param includeDot Se true, inclui o ponto no número da versão. 
--O parâmetro é opcional e o valor padrão é true.
--@return Retorna 1.1 para SOAP 1.1 ou 1.2 para SOAP 1.2
function wsdl:soapVersion(wsdlTable, includeDot)
  if includeDot == nil then
     includeDot = true
  end
  if wsdlTable[self.nsPrefix.."definitions"]._attr["xmlns:soap12"] then
     if includeDot then
        return "1.2"
     else
        return "12"
     end
  else
     if includeDot then
        return "1.1"
     else
        return "11"
     end
  end
end

---Obtém o namespace do Web Service
--@param wsdlTable Tabela lua gerada a partir do parse do conteúdo do WSDL
--@return Retorna o namespace obtido
function wsdl:getNamespace(wsdlTable)
  return wsdlTable[self.nsPrefix.."definitions"]._attr.targetnamespace 
end

---Obtém o endereço do serviço a partir do WSDL
--@param wsdlUrl URL do arquivo WSDL
--@return Retorna o endereço do serviço
function wsdl:getServiceUrl(wsdlUrl)
  return string.sub(wsdlUrl, 1, #wsdlUrl -5) 
end

--Obtém a lista de métodos do Web Service
--@param wsdlTable Tabela lua gerada a partir do parse do conteúdo do WSDL
--@return Retorna uma tabela com a lista de métodos obtidos
function wsdl:getMethods(wsdlTable)
  local methods, bindings = {}, wsdlTable[self.nsPrefix.."definitions"][self.nsPrefix.."binding"]
  --util.printable(bindings)
  local soapVersion = self:soapVersion(wsdlTable, false)
  for i, v in ipairs(bindings) do
    table.insert(methods, 
      { 
        bindingName=bindings[i]._attr.name, 
        operationName=bindings[i][self.nsPrefix.."operation"]._attr.name
      }
    )
  end
  return methods
end


-- -----------------------------------------------------------

---Inicia a aplicação
function main:start()
  osutil:clear()
  local wsdlUrl = ""
  if #arg >= 1 then
     wsdlUrl = arg[1]
  else
    --WSDL's de exemplo:
    --PHP: http://manoelcampos.com/estadosws/server.php?wsdl
    --ASP.NET: http://www.webservicex.net/CurrencyConvertor.asmx?WSDL
    io.write("WSDL URL: ")
    wsdlUrl = io.read()
  end
  if wsdl:phpWS(wsdlUrl) then
      print("Accessing PHP Web Service WSDL")
  end
  print("Downloading WSDL "..wsdlUrl..". Please wait...")
  local wsdlContent = http.request(wsdlUrl)

  wsdl:saveWsdl(wsdlContent, "ws.wsdl")
  local wsdlTable = wsdl:parseWsdl(wsdlContent)
  print()

  print("Service URL: ", wsdl:getServiceUrl(wsdlUrl))
  print("SOAP Version:", wsdl:soapVersion(wsdlTable))
  print("Namespace:", wsdl:getNamespace(wsdlTable))
  --print("Methods (choose a method by number):")
  print("Methods:")
  --local methodNumber = io.read()
  util.printable(wsdl:getMethods(wsdlTable))
  
  

  print()
end

-- -----------------------------------------------------------
main:start()
