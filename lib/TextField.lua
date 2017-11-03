require "util"

---TextField 0.8: Classe que implementa um campo de texto,
-- mapeando as teclas numéricas do controle remoto 
--para caracteres alfabéticos e numéricos, como
--ocorre com o teclado os telefones celulares.
--Baseado nos exemplos do Tutorial de NCLua,
--disponíveis em http://www.telemidia.puc-rio.br/~francisco/nclua/
--@author Manoel Campos da Silva Filho<br/>
--http://manoelcampos.com
TextField = {
    bgColor = "white",
    fontColor = "black",
    fontSize = 24,
    fontName = "vera",
	--Constante que mapeia as teclas numéricos do controle remoto
	--para seus respectivos caracteres
	KEYS = {
      ['1'] = {'@', '%', '"', '1', '-', '_', '=', '+', '/', '\\', '(', ')', '[', ']', '{', '}' },
      ['2'] = {'A', 'B', 'C', '2'},
      ['3'] = {'D', 'E', 'F', '3'},
      ['4'] = {'G', 'H', 'I', '4'},
      ['5'] = {'J', 'K', 'L', '5'},
      ['6'] = {'M', 'N', 'O', '6'},
      ['7'] = {'P', 'Q', 'R', 'S', '7'},
      ['8'] = {'T', 'U', 'V', '8'},
      ['9'] = {'W', 'X', 'Y', 'Z', '9'},
      ['0'] = {' ', '.', '#', '0', ',', ';', ':', '?', '!', '$', '*', '&'}
    },      		
	--De acordo com a quantidade de vezes que uma 
	--tecla numérica foi pressionada, define
	--a posição do caractere associado à tecla
	--que será impresso. Se a tecla for pressionada
	--duas vezes consecutivas, idx será 2, indicando
	--que deve ser impresso o segundo caractere 
	idx = 1,
	
	--Tempo de timeout entre o pressionamento de uma tecla numérica e outra.
	--Quando timeout expira, o pressionamento da tecla seguinte
	--imprimirá o primeiro caractere associado a ela.
	--Se o timeout não tiver expirado, é impresso
	--o caractere seguinte, associado a tecla numérica
	TIMEOUT = 800,
	--Ponteiro para a função que desregistra o timer
	--para avaliação do intervalo de pressionamento
	--das teclas numéricas
	unregTimeoutFunc = nil,
	--Texto produzido pelo pressionamento das teclas
	text = "",
	--Indica se os caracteres serão exibidos em maiúsculas 
	--ou minúsculas
	upcase = false,
	--Indica se será permitido alterar o case das letras
	allowCaseChange = false,
	--Posição horizontal do campo
	left = 0,
	--Posição vertical do campo
	top = 0,
	--Largura do campo
	width = 100,
	--Altura do campo
	height = 40,
	--Última tecla pressionada. Controle usado para que,
	--quando duas teclas diferentes são pressionadas em sequência,
	--o caractere associado à primeira tecla seja adicionado
	--imediatamente, sem aguardar o tempo de timeout. 
	--O caractere da segunda tecla só é adicionado
	--se o timeout dela expirar, ou uma terceira tecla
	--for pressionada (podendo ser até mesmo igual a primeira). 
    lastPressedKey = '',
    --Quantidade máxima de caracteres para o campo.
    --Zero indica que não há limite
    maxLenght = 0,
    --Indica se o campo permite múltiplas linhas, para funcionar como um campo memo
    multiLine = true,
    --Evento disparado quando uma tecla é pressionada. 
    --Assinatura: function (self, key) end
    onKeyPress = nil
} 

---Construtor da classe TextField
--@param left Posição horizontal do campo. Opcional
--@param top Posição vertical do campo. Opcional
--@param width Largura do campo. Opcional
--@param upcase Indica se é pra usar letras maiúsculas ou não. Opcional
--@param allowCaseChange Indica se é permitido alterar a case do texto. Opcional
--@param maxLenght Quantidade máxima de caracteres permitidas para o campo. Opcional
--@param multiLine Indica se o campo permite múltiplas linhas,
--@param linesCount Quantidade de linhas do campo. Opcional. O valor padrão é 1 
--para funcionar como um campo memo. Opcional
--@return Retorna uma instância de TextField
function TextField:new(top, left, width,  
 upcase, allowCaseChange, maxLenght, multiLine, linesCount)
	local o = {
		idx = self.idx,
		TIMEOUT = self.TIMEOUT,
		unregTimeoutFunc = nil,
		text = "",
		multiLine = multiLine or self.multiLine,
		upcase = upcase or self.upcase,
		allowCaseChange = allowCaseChange or self.allowCaseChange,
		left = left or self.left,
		top = top or self.top,
		width = width or self.width,
		maxLenght = maxLenght or self.maxLenght,
	}
	canvas:attrFont(self.fontName, self.fontSize)
	local tw, th = canvas:measureText("a")
	linesCount = linesCount or 0
	if linesCount <= 0 then
	   linesCount = 1
	end
	
	if multiLine then
	   linesCount = linesCount or 1
	else
	   linesCount = 1
	end
	o.height = th * linesCount
	setmetatable(o, self)
	self.__index = self
	o:paint()
	
	--TODO: Este tratamento de evento não é o ideal
	--quando a aplicação possuir mais de um campo,
	--o que é o comum de ocorrer. Assim, esta
	--implementação tem apenas a intenção
	--de ser utilizada por aplicações de exemplo.
	--Para uma aplicação com vários campos,
	--é preciso evoluir este modelo de tratamento
	--de eventos, criando um handler único
	--para todos os componentes, e não
	--um handler para cada componente, como
	--está sendo feito aqui.
	function o.handler(evt)
	  o:processKey(evt)
	end

    event.register(o.handler)	
	return o
end

---Retorna o caractere relativo a posição atual (self.idx)
--da tecla numérica pressionada
--@param key A tecla pressionada
--@return O caractere associado a posição self.idx 
--da tecla pressionada
function TextField:getChar(key)
    if key == "" then
       return key
    end
	local char = self.KEYS[key][self.idx]
	
	if self.upcase == false then
	   char = string.lower(char)
	end
	return char
end

---Quando chamada, indica que o tempo de timout
--entre o pressionamento de uma tecla encerrou,
--assim, a tecla deve ser adicionada ao texto 
--já digitado.
--@param key Tecla numérica pressionada
function TextField:keyPressTimeout(key)
	self.unregTimeoutFunc = nil
    if (self.maxLenght == 0) or (#self.text < self.maxLenght) then
       self.text = self.text .. self:getChar(key)
    end
	
	self.idx = 1
	self.lastPressedKey = ""
	print("Timeout")
end

---Registra a função de timeout para executar depois
--de self.TIMEOUT milisegundos, para identificar quando houver
--timeout entre o pressionamento de uma tecla e outra,
--e somente então, adicionar a tecla ao texto já digitado
--@param key Tecla numérica pressionada
function TextField:registerTimeout(key)
     self.lastPressedKey = key
     self.unregTimeoutFunc = 
       event.timer(self.TIMEOUT, 
         function () self:keyPressTimeout(key) end)
end

---Desregistra a função de timeout.
--Este método deve ser chamado sempre que
--o usuário pressionar uma tecla antes
--do tempo de timeout definido em self.TIMEOUT.
--Com isto, a tecla pressionada anteriormente
--é descartada.
function TextField:unregisterTimeout()
  	 if self.unregTimeoutFunc ~= nil then
  	 	self.unregTimeoutFunc()
	 end
end

---Desenha o texto na inteface gráfica
--@param tmpText Texto a ser impresso. Se for omitido,
--o valor do atributo text é impresso
function TextField:paint(tmpText)
  tmpText = tmpText or self.text or ""
  local cursor = '|'
  local space = 2
  local x = self.left+space
    
  canvas:attrColor(self.bgColor)
  --o arquivo tiresias.ttf deve estar em /usr/local/share/fonts/truetype
  canvas:attrFont(self.fontName, self.fontSize)
  canvas:drawRect('fill', self.left, self.top, self.width, self.height)
  canvas:attrColor(self.fontColor)  
  if self.multiLine then
     util.paintBreakedString(self.width, x, self.top, tmpText..cursor)
     --local tw, _ = canvas:measureText(ln)
     --canvas:drawText(self.left+tw-space, y, cursor)     
  else
	 canvas:drawText(x, self.top, tmpText)
	 local tw, _ = canvas:measureText(tmpText)
	 canvas:drawText(self.left+tw-space, self.top, cursor)
  end
  canvas:flush()
  print("text", "'"..tmpText.."'",  "Len: "..#tmpText)
  
end

---Implementa o tratamento do pressionamento das teclas
--numéricas do controle remoto. Este método
--deve ser chamado dentro de uma função tratadora de eventos.
--@param evt Objeto da classe event recebido 
function TextField:processKey(evt)
  if evt.class~="key" or evt.type~="press" then
  	 return
  end
  
  local key = evt.key
  --print("key", key, string.byte(key))
  --Verifica se foi pressionada um tecla numérica no controle remoto
  if tonumber(key) then
     if self.lastPressedKey == key or self.lastPressedKey == "" then
	     --Se o timeout de pressionamento de teclas não expirou,
	     --desregistra a função de timeout anteriormente registrada
	     --e passa para o próximo caractere associado à tecla numérica
	     --pressionada, descartando o caractere anterior.
	     --Uma tecla pressionada só é incluída no texto
	     --quando o timeout expira ou quando for pressionadas
	     --teclas diferentes entre um pressionamento e outro.
	     --Por exemplo, se o usuário pressionar a tecla 1 e depois
	     --a tecla 2, a caractere associado a 1 é incluído
	     --e depois o associado a tecla 2 entrará no processo
	     --de timeout. Se o timeout expirar, ela é incluída também.s
	  	 if self.unregTimeoutFunc ~= nil then
	  	 	self.unregTimeoutFunc()
	  	 	self.idx = self.idx + 1
	  	 	if self.idx > #self.KEYS[key] then
	  	 	   self.idx = 1
	  	 	end
	  	 end
  	 else
	     --Cancela o timeout da última tecla pressionada.
	     --A mesma será confirmada antes dele expirar
  	     self:unregisterTimeout()
         --Se a tecla pressionada anteriormente é diferente da atual,
         --valida a tecla anterior imediatamente, incluido  no texto, o caractere
         --associado à ela. A nova tecla entrará em processo
         --de timeout. Quando o timeout expirar, o caractere associado
         --a nova tecla é inserido.
  	     self:keyPressTimeout(self.lastPressedKey)
  	 end
  	 
     if (self.maxLenght == 0) or (#self.text < self.maxLenght) then
	     local tmp = self.text..self:getChar(key)
	     self:paint(tmp)
	     self:registerTimeout(key)
     end  	   	 
  --se é um caractere alfabético ou símbolo, o usuário possui um teclado
  --e a entrada de dados é direta
  elseif string.find(
  "ABCDEFGHIJKLMNOPQRSTUVWXYZ"..
  "abcdefghijklmnopqrstuvwxyz"..
  ".-,:;()[]{}=+-_*&%$#@!?/\\<>", key) ~= nil then
     --Cancela o timeout da última tecla pressionada (se houver).
     --A mesma será confirmada antes dele expirar
     self:unregisterTimeout()
     --Se a tecla pressionada anteriormente é diferente da atual,
     --valida a tecla anterior imediatamente, incluido  no texto, o caractere
     --associado à ela. A nova tecla entrará em processo
     --de timeout. Quando o timeout expirar, o caractere associado
     --a nova tecla é inserido.
     self:keyPressTimeout(self.lastPressedKey)
     
     if (self.maxLenght == 0) or (#self.text < self.maxLenght) then
	     self.text = self.text..key
	     self:paint()
     end     
  --A seta para à esquerda funcionará como Backspace
  elseif key == "CURSOR_LEFT" then
     --Cancela o timeout da última tecla pressionada.
     --A mesma será confirmada antes dele expirar
  	 self:unregisterTimeout()
     --Confirma a última tecla pressionada, não
     --esperando o timeout dela expirar para
     --o caractere associado à mesma ser incluído
  	 self:keyPressTimeout(self.lastPressedKey)
  	 self.text = string.sub(self.text, 1, #self.text-1) 
  	 self:paint()
  	 self.lastPressedKey = ""
  --A seta para à esquerda funcionará como espaço
  elseif key == "CURSOR_RIGHT" then
     if self.text ~= "" and string.sub(self.text, #self.text) ~= " " then
	     --Cancela o timeout da última tecla pressionada.
	     --A mesma será confirmada antes dele expirar
	     self:unregisterTimeout()
	     --Confirma a última tecla pressionada, não
	     --esperando o timeout dela expirar para
	     --o caractere associado à mesma ser incluído
	     self:keyPressTimeout(self.lastPressedKey)
	     self.lastPressedKey = ""
	     
	     if self.maxLenght == 0 or #self.text < self.maxLenght then
	         self.text = self.text .. ' '   
	         self:paint()
	     end	      
     end
  --A seta para cima funcionará como Caps Lock ON
  elseif key == "CURSOR_UP" then
     if self.allowCaseChange then
  	    self.upcase = true
  	 end
  --A seta para baixo funcionará como Caps Lock OFF
  elseif key == "CURSOR_DOWN" then
     if self.allowCaseChange then
        self.upcase = false
     end
  end
  
  if self.onKeyPress ~= nil then
     self:onKeyPress(key)
  end
end
