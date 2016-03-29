---Exemplo para acesso a Web Service de rastreamento de encomendas postadas pelos Correios

--Adiciona o diretório lib ao path de bibliotecas, para que a aplicação encontre
--os módulos disponibilizados
package.path = package.path .. ';lib/?.lua'

require "ncluasoap"
require "util"
--Como o TextField não é um módulo, é preciso usar dofile para incluí-lo
dofile("lib/TextField.lua")

--"Classe" principal da aplicação, que contém todas as funções e atributos
--usados
local main = {
	l = 160,
	txtCodRastreamento = false
}

--Obtém as dimensões do canvas
main.w, main.h = canvas:attrSize()

---Envia a requisição SOAP
function main.enviaRequisicao()
   ncluasoap.call(
     main.createMsg(main.txtCodRastreamento.text), 
     main.getResponse, "1.1")
   main.paintBackgroundRect("media/fundo2.png")
   local s = "Processando. Por favor, aguarde..."
   local tw, th = canvas:measureText(s)
   --realiza cálculos para colocar o texto no centro da região do canvas
   local x, y = (main.w-tw)/2, 400
   main.drawText(s, true, false, x, y)
end

---Desenha uma mensagem na tela
--@param text Texto a ser desenhado
--@param flush Se é pra dar um flush no canvas, e exibir as alterações
--feitas nele. O valor padrão é true.  
--@param clear Indica se a área do canvas deve ser limpa ou não. O valor padrão é true
--@param x Posição horizontal onde o texto deve ser impresso
--@param y Posição vertical onde o texto deve ser impresso
--@param color Cor da fonte a ser utilizada
function main.drawText(text, flush, clear, x, y, color)
  x = x or main.l
  y = y or 0
  if clear == nil then
     clear = true
  end
  if flush == nil then
     flush = true
  end
  if clear then
     main.paintBackgroundRect("media/fundo1.png")
  end
  color = color or "black"
  canvas:attrColor(color)
  canvas:attrFont("vera", 26)
  canvas:drawText(x, y, text)   
  if flush then
     canvas:flush()
  end       
end

---Desenha a imagem de fundo da app
--@param imgPath Caminho do arquivo de imagem a ser usado no fundo
function main.paintBackgroundRect(imgPath)
     local img = canvas:new(imgPath)
     canvas:attrColor(255,255,255, 0)
     canvas:clear()
     canvas:compose(0, 0, img)
     canvas:attrColor("black")
     canvas:attrFont("vera", 26)
end

---Exibe o botão fechar, calculando
--as coordenadas para que ele fique 
--na parte inferior direita da área do canvas.
--A função não realiza um canvas:flush, que 
--deve ser executado posteriormente quando desejado.
--@param x Posição horizontal do botão. Se omitido, será colocado no canto esquerdo
--@param y Posição vertical do botão. Se omitido, será colocado no canto inferior
function main.paintCloseBtn(x, y)
  local img = canvas:new("media/fechar.png")
  local w, h = img:attrSize()
  local x, y = x or 5, y or (main.h - h + 5)
  canvas:compose(x, y, img)
end

---Função para processar a resposta da requisição SOAP enviada ao WS
--@param result Resultado da chamada ao método remoto via SOAP.
--No caso deste Web Service, o resultado é uma variável primitiva simples (ou seja, contendo apenas um valor)
function main.getResponse(retorno)
   print("\n\n-------------"..retorno, "\n\n")

  local x, y = 260, 380
  --Se não tem um ; na string de retorno, é porque
  --houve erro (isso é especificado pelo WS sendo consumido).
  if string.find(retorno, ";") == nil then
     main.paintBackgroundRect("media/fundo2.png")
     util.paintBreakedString(main.w, x-130, y+25, retorno)
  else
     local data, localidade, situacao = "", "", ""
     local i = string.find(retorno, ";")
     data = string.sub(retorno, 1, i-1)
     
     j = string.find(retorno, ";", i+1)
     localidade = string.sub(retorno, i+1, j-1)
     
     situacao = string.sub(retorno, j+1, #retorno)     
     
     print("Data: "..data .. " Local: "..localidade .. " Situação: "..situacao)

     main.paintBackgroundRect("media/fundo2.png")
	   local tw, th = canvas:measureText("A")
     th = th - 5
  	 canvas:drawText(x, y, data)   
	   y = y + th
     x = 130
	   canvas:drawText(x, y, localidade)
     y = y + th
     canvas:drawText(x, y, situacao)
  end
  main.paintCloseBtn()  
  canvas:flush()
  
  --a cada 1 minuto, envia nova requisição ao site dos
  --correios, para verificar se a situação da encomenda mudou.
  event.timer(60000, main.enviaRequisicao)
end

---Gera a tabela lua contendo os parâmetros
--para chamada do método no WebService.
--@param codRastreamento Código de rastreamento da encomenda
--nos Correios (13 caracteres)
function main.createMsg(codRastreamento)
 return {
    address = "http://rastreador.manoelcampos.com/soap.php",
    namespace = "rastreador.manoelcampos.com/soap.php",
    operationName = "situacaoEncomenda",
    params = {
      codRastreamento = codRastreamento --"SW199673643BR"
    }    
 }
end

---Função tratadora de eventos
--@param evt Tabela contendo os parâmetros
--dos eventos disparados.
function main.handler(evt)
  local fieldTop, fieldWidth, left = 440, 300, 250

  if evt.class=="ncl" and evt.type=="presentation" and evt.action=="start" then
     main.paintBackgroundRect("media/fundo1.png")

     --Obtém a largura e altura do texto passado ao measureText, considerando a fonte atual do canvas
     --A variável th é usada para saber quantos pixels deve-se pular para imprimir uma frase
     --numa linha abaixo da que foi impressa, utilizando main.drawText
     local tw, th = canvas:measureText("A")
     th = th-4
    
                                           --top, left, width, upcase, allowCaseChange, maxLenght
     main.txtCodRastreamento = TextField:new(fieldTop, left, fieldWidth, false, true, 13)
     local img = canvas:new("media/ok.png")
     local iw, ih = img:attrSize()
     canvas:compose(main.w-(iw+10), fieldTop-10, img)
     main.paintCloseBtn(58, 235)

     canvas:flush()
  elseif evt.class=="key" and evt.type=="press" and evt.key=="ENTER" then
     if #main.txtCodRastreamento.text == 13 then
        main.enviaRequisicao()
     else
       main.drawText("O código deve ter 13 caracteres", true, false, left-60, 290, "red")
     end
  end 
end

--Registra a função handler como tratadora de eventos
event.register(main.handler)
