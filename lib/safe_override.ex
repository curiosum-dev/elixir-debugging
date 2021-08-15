defmodule SafeOverride do
  @moduledoc """
  Boilerplate to _safely_ override a pre-existing macro or function in a way
  that allows multiple libraries that override the same function
  to dispatch to the next one as fallback transparently.


  ## Usage

  From a module where you want to override a function or macro:
  1. call `use SafeOverride [name: arity, other_name: other_arity]`
  2. write a `__using__/1` macro where you include a call to `SafeOverride.import_code_for(YourModule, [name: arity, other_name: other_arity])`
  3. Define the functions or macros you want to override _as macros_ where you can call the fallback implementation using `super(params, here)`.

  When someone now calls `use YourModule`, this will bring your module's implementation in scope, hide all conflicting imports and register a module-attribute such that when they call your macros and you call the fallback implementation, this will dispatch to the implementation that was in scope before the `use YourModule` statement.

  ### Note

  Because of how the dispatching logic is structured, you always have to implement the overridden signature as a macro, even if it was originally a function in the external module.
  """

  @doc """
  Injects code that safely falls back to implementations that were in scope before `use YourModule` was used,
  into your module.
  """
  defmacro __using__(signatures) do
    macro_inspect(define_safe_overrides(signatures, __CALLER__))
  end

  @doc """
  Injects the proper imports into a module that calls `use YourModule` to hide the macros you are overriding,
  bring your overridden versions in scope,
  and register what fallback to use when you call `super` from your macro implementation.
  """
  defmacro import_code_for(module, signatures) do
    module = Macro.expand(module, __CALLER__)
    signatures_with_modules = SafeOverride.lookup_signature_modules(signatures, __CALLER__)
    Module.put_attribute(__CALLER__.module, Module.concat(SafeOverride.Overrides, module), signatures_with_modules)
    import_excepts = SafeOverride.build_import_excepts(signatures_with_modules, __CALLER__)
    quote location: :keep do
      unquote(import_excepts)
      import unquote(module), only: unquote(signatures)
    end
    |> macro_inspect()
  end

  @doc false
  # For all signatures that are overridden,
  # find the matching module in the imports of `caller`.
  def lookup_signature_modules(names, caller) do
    for {name, arity} <- names, into: %{} do
      case find_module(name, arity, caller.functions) do
        nil ->
          case find_module(name, arity, caller.macros) do
            nil ->
              raise "Attempted to safely override function #{name}/#{arity} that is not imported!"
            module ->
              {{name, arity}, module}
          end
        module ->
          {{name, arity}, module}
      end
    end
  end

  defp find_module(function, arity, functions_or_modules_list) do
    module = Enum.find_value(functions_or_modules_list, fn {module, imports} ->
      {function, arity} in imports && module
    end)

    module
  end

  # Creates overridable macro-definitions
  # that call whatever happens to be in scope
  # (of the same name+arity)
  # in the __CALLER__.
  defp define_safe_overrides(names, caller) do
    for {name, arity} <- names do
      define_safe_override(name, arity, caller)
    end
  end

  defp define_safe_override(name, arity, caller) do
    params = Macro.generate_arguments(arity, caller.module)
    module = Macro.expand(caller.module, caller)
    quote location: :keep do
      defmacro unquote(name)(unquote_splicing(params)) do
        name = unquote(name)
        arity = unquote(arity)
        params = unquote(params)
        module = Module.get_attribute(__CALLER__.module, Module.concat(SafeOverride.Overrides, unquote(module)))[{name, arity}]
        quote location: :keep do
          unquote(module).unquote(name)(unquote_splicing(params))
        end
      end
      defoverridable [{unquote(name), unquote(arity)}]
    end
    |> macro_inspect()
  end

  @doc false
  # Returns AST that adds all of the correct `import Module, exept: ...`
  # for all signatures we are overriding.
  def build_import_excepts(signatures, caller) do
    for {{name, arity}, module} <- signatures do
      build_import_except(module, name, arity, caller)
    end
  end

  defp build_import_except(module, name, arity, _caller) do
    quote do
      import unquote(module), except: [{unquote(name), unquote(arity)}]
    end
  end


  # Debug helper to show what kind of AST macros end up creating.
  def macro_inspect(ast) do
    # IO.puts(Macro.to_string(ast))
    ast
  end
end
