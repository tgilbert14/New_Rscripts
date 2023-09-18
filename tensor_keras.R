## Run in order to set up ------------------------------------------------------
library(tensorflow)
##checking version of python
#reticulate::install_python()

##making environment for python->tensorflow/keras
install_tensorflow(envname = "r-tensorflow")
library(keras)
#confirm that the installation
tf$constant("Hello TensorFlow!")
#-------------------------------------------------------------------------------
#tensorflow::
#keras::

## Overeview -------------------------------------------------------------------
x <- as_tensor(1:6, dtype = "float32", shape = c(2, 3))
x
# size of the tensor along each of its axes
x$shape
# type of all the elements in the tensor
x$dtype
## math operation - for machine learning
x + x
5 * x
## multiplying matrix by matrix
tf$matmul(x, t(x)) 
## concates along dimension
tf$concat(list(x, x, x), axis = 0L)
## other things
tf$nn$softmax(x, axis = -1L)
sum(x) # same as tf$reduce_sum(x)

## may need to change this?? Running on CPU
if (length(tf$config$list_physical_devices('GPU'))) {
  message("TensorFlow **IS** using the GPU")
} else {message("TensorFlow **IS NOT** using the GPU")}

## To store model weights (or other mutable state)
var <- tf$Variable(c(0, 0, 0))
var
var$assign(c(1, 2, 3))
var$assign_add(c(1, 1, 1))

## gradient descent/algos
x <- tf$Variable(1.0)

f <- function(x) {
  x^2 + 2*x - 5
}
  
f(x)
## getting derivative -->
with(tf$GradientTape() %as% tape, {
  y <- f(x)
})
g_x <- tape$gradient(y, x)  # g(x) = dy/dx
g_x

## graphs and tf_function
## used to seperate tensorflow code from R to speed up process
my_func <- tf_function(function(x) {
  message('Tracing.')
  tf$reduce_sum(x)
})

x <- as_tensor(1:3)
my_func(x)

x <- as_tensor(10:8)
my_func(x)

## same thing but updating type
x <- as_tensor(c(10.0, 9.1, 8.2), dtype=tf$dtypes$float32)
my_func(x)

## export graphs?
#tf$saved_model

## tf$Module for managing tf$Variable and tf_function that operates them
## save and restore the values of your variables using 
tf$train$Checkpoint
##  This is useful during training as it is quick to save and restore a model’s state

## You can import and export the tf$Variable values and the tf$function graphs using
tf$saved_model
## This allows you to run your model independently of the Python program that created it

## e.g., tf$Module
MyModule(tf$Module) %py_class% {
  initialize <- function(self, value) {
    self$weight <- tf$Variable(value)
  }
  
  multiply <- tf_function(function(self, x) {
    x * self$weight
  })
}

mod <- MyModule(3)
mod$multiply(as_tensor(c(1, 2, 3), "float32"))

save_path <- tempfile()
tf$saved_model$save(mod, save_path)

## can re-load the model in to use
reloaded <- tf$saved_model$load(save_path)
reloaded$multiply(as_tensor(c(1, 2, 3), "float32"))

tf$keras$layers$Layer ## and
tf$keras$Model
## classes build on tf$Module providing additional functionality and
## convenience methods for building, training, and saving models

## Put all together to build basic model to train from scratch -->
x <- as_tensor(seq(-2, 2, length.out = 201), "float32")
x
f <- function(x) {
  x^2 + 2*x - 5
}

f(x)

ground_truth <- f(x)

y <- ground_truth + tf$random$normal(shape(201))

x %<>% as.array()
y %<>% as.array()
ground_truth %<>% as.array()

plot(x, y, type = 'p', col = "deepskyblue2", pch = 19)
lines(x, ground_truth, col = "tomato2", lwd = 3)
legend("topleft", 
       col = c("deepskyblue2", "tomato2"),
       lty = c(NA, 1), lwd = 3,
       pch = c(19, NA), 
       legend = c("Data", "Ground Truth"))

## now create a model
Model(tf$keras$Model) %py_class% {
  initialize <- function(units) {
    super$initialize()
    self$dense1 <- layer_dense(
      units = units,
      activation = tf$nn$relu,
      kernel_initializer = tf$random$normal,
      bias_initializer = tf$random$normal
    )
    self$dense2 <- layer_dense(units = 1)
  }
  
  call <- function(x, training = TRUE) {
    x %>% 
      .[, tf$newaxis] %>% 
      self$dense1() %>% 
      self$dense2() %>% 
      .[, 1] 
  }
}

model <- Model(64)


untrained_predictions <- model(as_tensor(x))

plot(x, y, type = 'p', col = "deepskyblue2", pch = 19)
lines(x, ground_truth, col = "tomato2", lwd = 3)
lines(x, untrained_predictions, col = "forestgreen", lwd = 3)
legend("topleft", 
       col = c("deepskyblue2", "tomato2", "forestgreen"),
       lty = c(NA, 1, 1), lwd = 3,
       pch = c(19, NA), 
       legend = c("Data", "Ground Truth", "Untrained predictions"),cex = 0.6)
title("Before training")

## with basic loop training
variables <- model$variables

optimizer <- tf$optimizers$SGD(learning_rate=0.01)

for (step in seq(1000)) {
  
  with(tf$GradientTape() %as% tape, {
    prediction <- model(x)
    error <- (y - prediction) ^ 2
    mean_error <- mean(error)
  })
  gradient <- tape$gradient(mean_error, variables)
  optimizer$apply_gradients(zip_lists(gradient, variables))
  
  if (step %% 100 == 0)
    message(sprintf('Mean squared error: %.3f', as.array(mean_error)))
}

trained_predictions <- model(x)
plot(x, y, type = 'p', col = "deepskyblue2", pch = 19)
lines(x, ground_truth, col = "tomato2", lwd = 3)
lines(x, trained_predictions, col = "forestgreen", lwd = 3)
legend("topleft", 
       col = c("deepskyblue2", "tomato2", "forestgreen"),
       lty = c(NA, 1, 1), lwd = 3,
       pch = c(19, NA), 
       legend = c("Data", "Ground Truth", "Trained predictions"))
title("After training")

## BUT -> keras has built in models to use (tf$keras) - compile/fit
new_model <- Model(64)

new_model %>% compile(
  loss = tf$keras$losses$MSE,
  optimizer = tf$optimizers$SGD(learning_rate = 0.01)
)

history <- new_model %>% 
  fit(x, y,
      epochs = 100,
      batch_size = 32,
      verbose = 0)

model$save('./my_model')
plot(history, metrics = 'loss', method = "base") 
#-- End of Overview ------------------------------------------------------------

#-- Intro to Tensors -----------------------------------------------------------
