local ClassNLLCriterion, parent = torch.class('nn.ClassNLLCriterion', 'nn.Criterion')

function ClassNLLCriterion:__init(weights)
   parent.__init(self)
   self.sizeAverage = true
   self.outputTensor = torch.Tensor(1)
   if weights then
       assert(weights:dim() == 1, "weights input should be 1-D Tensor")
       self.weights = weights
   end
end

function ClassNLLCriterion:updateOutput(input, target)
   if input:type() == 'torch.CudaTensor' and not self.weights then
       input.nn.ClassNLLCriterion_updateOutput(self, input, target)
       self.output = self.outputTensor[1]
       return self.output
   end

   if input:dim() == 1 then
      self.output = -input[target]
      if self.weights then
          self.output = self.output*self.weights[target]
      end
   elseif input:dim() == 2 then
      local output = 0
      for i=1,target:size(1) do
         if self.weights then
            output = output - input[i][target[i]]*self.weights[target[i]]
         else
            output = output - input[i][target[i]]
         end
      end
      if self.sizeAverage then
         output = output / target:size(1)
      end
      self.output = output
   else
      error('matrix or vector expected')
   end
   return self.output
end

function ClassNLLCriterion:updateGradInput(input, target)
   self.gradInput:resizeAs(input)
   self.gradInput:zero()

  if input:type() == 'torch.CudaTensor' and not self.weights then
      input.nn.ClassNLLCriterion_updateGradInput(self, input, target)
      return self.gradInput
  end

  if input:dim() == 1 then
      self.gradInput[target] = -1
      if self.weights then
          self.gradInput[target] = self.gradInput[target]*self.weights[target]
      end
  else
      local z = -1
      if self.sizeAverage then
         z = z / target:size(1)
      end
      for i=1,target:size(1) do
          self.gradInput[i][target[i]] = z
         if self.weights then
             self.gradInput[i][target[i]] = self.gradInput[i][target[i]]*self.weights[target[i]]
         end
      end
   end
   return self.gradInput
end
