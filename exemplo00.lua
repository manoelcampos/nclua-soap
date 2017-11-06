---Aplicação de exemplo que consome Web Service para conversão de moedas.
--@author Manoel Campos da Silva Filho<br>
--<a href="http://manoelcampos.com">http://manoelcampos.com</a>

--Adiciona o diretório lib ao path de bibliotecas, para que a aplicação encontre
--os módulos disponibilizados
package.path = package.path .. ';lib/?.lua'
 
local function main()
  require "ncluasoap"
  
  ---Função para processar a resposta da requisição SOAP enviada ao WS
  --@param result Resultado da chamada ao método remoto via SOAP.
  --No caso deste Web Service, o resultado é uma variável primitiva simples (ou seja, contendo apenas um valor)
  local function getResponse(result)
    --Forma de uso com NCLua SOAP anterior a 0.5.6
    --print("\n\n---------Cotação do Dolar em Reais:", result.ConversionRateResult, "\n\n")
  
    print("\n\n\n--------------------------------RESULTADO--------------------------------")
    print("         Cotação do Dolar em Reais:", result)
    print("--------------------------------RESULTADO--------------------------------\n\n\n")
  
  
    --Finaliza o script lua. Um link no NCL finalizará a aplicação NCL quando o nó lua for finalizado
    event.post {class="ncl", type="presentation", action="stop"}
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

  ncluasoap.debug = true
  
  --Executa o método remoto, definido dentro da msgTable,
  --gerando uma requisição SOAP, enviando ao WS e obtendo o resultado.
  --getResponse é uma função de callback que será executada
  --automaticamente, assim que a resposta da chamada remota for obtida.
  ncluasoap.call(msgTable, getResponse)

  --Esta linha é executada automaticamente após a chamada de ncluasoap.call
  --A chamada a ncluasoap.call retorna imediatamente, pois é uma chamada
  --assíncrona, devido à particularidades do módulo TCP de NCLua.
  --Assim, NÃO é possível obter o retorna do método remoto
  --fazendo algo como retorno = ncluasoap.call(msgTable).
  --Tal instrução não funciona.
  print("---------------------------Chamou ncluasoap.call")
end

--Chama a função main que executará a chamada ao WS
--em modo protegido, permitindo tratar erros gerados.
local ok, res = pcall(main)

if not ok then
   print("\n\nError: "..res, "\n\n")
   return -1
end
