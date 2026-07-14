defmodule GreetSteps do
  use Cucumber.StepDefinition
  import ExUnit.Assertions

  step "a greet agent is running", context do
    # Initialize greet session state
    Map.put(context, :session, %{
      name: nil,
      greeted: false,
      messages: []
    })
  end

  step "I send {string}", %{args: [message]} = context do
    session = context[:session]

    # Simulate greet agent responses
    response = simulate_greet(session, message)

    # Update session with new state and message
    updated_session = update_session(session, message, response)

    context
    |> Map.put(:session, updated_session)
    |> Map.put(:last_message, message)
    |> Map.put(:last_response, response)
  end

  step "I receive {string}", %{args: [expected]} = context do
    actual = context[:last_response]

    # Check if actual response contains or matches expected
    assert String.downcase(actual) =~ String.downcase(expected),
      "Expected '#{expected}' in response '#{actual}'"

    context
  end

  # Simulate greet agent behavior
  defp simulate_greet(%{name: nil, greeted: false}, message) do
    if String.downcase(message) == "hello" do
      "Who am I talking to?"
    else
      # If first message isn't hello, still ask for name
      "Who am I talking to?"
    end
  end

  defp simulate_greet(%{name: nil, greeted: true}, message) do
    # User hasn't provided name yet
    if String.downcase(message) in ["hello", "hi"] do
      "Who am I talking to?"
    else
      # Treat message as the name
      "Wonderful to meet you, #{String.downcase(message)}"
    end
  end

  defp simulate_greet(%{name: name}, message) when not is_nil(name) do
    # Already have a name, respond to messages
    case String.downcase(message) do
      msg when msg in ["how are you?", "how are you", "how r u"] ->
        "I am Greeeet"
      _ ->
        "I am Greeeet"
    end
  end

  defp simulate_greet(_session, _message) do
    "Who am I talking to?"
  end

  # Update session state based on interaction
  defp update_session(session, message, response) do
    cond do
      # First interaction - setting greeted flag
      not session.greeted and String.downcase(message) == "hello" ->
        Map.put(session, :greeted, true)

      # User providing name
      session.greeted and is_nil(session.name) and String.contains?(response, ["Wonderful", "wonderful"]) ->
        Map.put(session, :name, String.downcase(message))

      true ->
        session
    end
  end
end
