# Cuban Linx

## Installation
```ruby
gem install cuban_linx

require "cuban_linx"
```
Or add to your gem file
```ruby
gem "cuban_linx"
```

## Usage
By including the call chain module a class will have access to the two class methods to build a functional chain: 
* `define_link`
* `execution_chain`

```ruby
class Procedure
  include CubanLinx::CallChain
  ...
end
```

#### Execution Chains
  Adding `execution_chain` macro can be as simple as:
  ```ruby
  execution_chain :procedure_name, functions: [-> (*) { :ok }]

  # then
  def call
    procedure_name.call(initial_id: id)
  end
  ```
  
The macro creates an instance method based on the name argument and wraps each function. Then invoking the `call` method passes keyword arguments which are wrapped as payload object and passed to the first function. The `call` method will return a tuple/array where the first item/key will be: `:ok`, `:no_op` or `:error`.

The second item is a hash with keys for `messages` and `errors`, each of which is a hash. After calling each function in the chain a new payload object is passed to the next function. Because the functions have been wrapped there is pattern matching that will pass the payload through if the key is either `:error` or `:no_op` and to only call the underlying function if the key is `:ok`.
Examples
* `:ok`
```ruby
  [
    :ok,
    { messages:
      {
        warnings: #<Set: {"dropped attributes"}>,
        user: {"id"=>42, "last_name"=>"Kuhlman"}, :business_id=>42},
        errors: {}
      }
    }
  ]
```
* `:error`
```ruby
  [
    :error,
    { messages:
      {
        warnings: #<Set: {}>,
        user_id: 42,
        errors: { user: [:not_found] }
      }
    }
  ]
```
* `:no_op`
```ruby
  [
    :no_op,
    { messages:
      {
        warnings: #<Set: {}>,
        user_id: 42,
        errors: { user: [:not_found] }
      }
    }
  ]
```

You can also yield the result to a block:
```ruby
  execution_chain :procedure_name, functions: [-> (*) { :ok }]

  # then
  def call
    procedure_name.call(initial_id: id) do |result|
      case result
      in [:ok, *]
        ...
      in [:error, *]
        ...
      in [:no_op, *]
      end
    end
end
```


#### Defining Functions

Clearly defining the procs inline won't scale for more complex procedures.

**Methods**

A method can be defined like this:
```ruby
def payload_inspect
  ->(payload) { puts payload.inspect }
end

# added to the call by passes the method name as symbol

execution_chain :procedure_name, functions: [:payload_inspect]
```

**Macro**

Creates an instance method that returns block as a lambda
```ruby
define_link :payload_inspect do |payload|
  puts payload.inspect
  :ok
end

execution_chain :procedure_name, functions: [:payload_inspect]
```

**Ok Returns**

If the function returns `nil` `:ok` `true` `[:ok, {}]` `[:ok, {}, {}]` then the next function in the chain will be called. For `nil` `:ok` `true` the messages and errors will not be updated. For a tuple like
```ruby
[:ok, { user: { id: 23 } }]
```
then the hash will be merged into the messages hash. For the last example which would look like:
```ruby
[:ok, { user: { id: 23 } }, { registration: "was not found" }]
```
then the first hash is merged into the messages and the second hash merges onto the payload's `errors` hash. So to be clear the presence of errors messages is not intended to be a blocker per se, but the intent is to to allow the aggregation of errors and then determine if the key should be switched to `errors` or `no_op`  later in the chain.

**No op Returns**

When the function returns `:no_op` then the key is changed and the messages and error hashes are passed through. If a tuple with a hash is returned: 
```ruby
[:no_op, { user: { id: 23 }]
```
Then the hash is merged on the message and the key is changed
When retuning a tuple with two hashes the second is merged onto the errors:
```ruby
[:no_op, { user: { id: 23 }, { registration: "not found" }]
```

**Error Returns**

When the function returns `:error` then the key is changed and the messages and error hashes are passed through. If a tuple with a hash is returned: 
```ruby
[:error, { user: { lookup: "failed" }]
```
Then the hash is merged on the errors and the key is changed
When retuning a tuple with two hashes the first is merged on the messages hash and second is merged onto the errors:
```ruby
[:no_op, { user: { id: 23 }, { registration: "not found" }]
```

 
#### Payloads
The arguments passed to the call chain are wrapped as a payload object. This class internally has `messages` and `errors` hashes that can be accessed through the public API:

**Delete**

```ruby
  define_link :lookup_user do |payload|
    user_id = payload.delete(:user_id)
    User.find_by(id: user_id).then do |potential_user|
      if potential_user.nil?
        [:error, { user_lookup: "Could not find user w/ id: #{user_id}" }]
      else
        [:ok, { user: potential_user }]
      end
    end
  end
```

**Fetch**
```ruby
  define_link :format_user do |payload|
    payload.fetch(:user).then do |user|
      [
        :ok,
        {
          user: user.attributes.slice("id", "last_name"),
          business_id: user.business_id,
        },
      ]
    end
  end
```
In the above example for the user object assume that it is an active record instance and attributes provides a hash. 

**Warnings**

Warnings is a set of warnings that is stored under the messages hash and is publicly available as a warnings message. Again it might be worth building up warnings before changing to an `:error`. Warnings can be set wherever messages are being merged in, and can be a string or an array of strings and they will be included in the set.
```ruby
define_link :user_lookup do |payload|
  payload.delete(:user_id).then do |user_id|
    User.find(user_id).then do |potential_user|
      if potential_user.nil?
        { user: NullUserObject.new, warnings: "not found" }
      else
        { user: potential_user }
      end
    end
  end
end

def check_warnings
  lambda { |payload|
    return unless payload.warnings.include?("not found") && strict_mode?

    [:error, { user: "not found in strict mode" }]
  }
end

execution_chain :user_lookup_chain, functions: [:user_lookup, :check_warnings]
```

**Method Missing**

Because why not? It's Ruby after all...
The payload's method missing checks if the method name is a key in messages hash and returns uses fetch.
```ruby
define_link :user_lookup do |payload|
  payload.user_id.then do |user_id|
    User.find(user_id).then do |potential_user|
      if potential_user.nil?
        { user: NullUserObject.new, warnings: "not found" }
      else
        { user: potential_user }
      end
    end
  end
end
```

#### A Few Notes
The functions are executed evaluated at the instance level. This means that, in the example above the reference to `strict_mode?` might have been confusing, but this could be a wrapper around an environment variable, feature flag etc. as an instance method. This leads to some interesting possibilities, and I will now editorialize a bit. You could do something like this:
```ruby
define_link :bad_user_lookup do |payload|
  @user = User.find(payload.fetch(:user_id))
  :ok
end

define_link :to_be_called_later do |payload|
  safe_user = @user || NullUserObject.new
  [:ok, { user: safe_user }]
end
```
Instance methods and objects passed through initialization are both fine and even encouraged. 
```ruby
def initialize(user)
  @user = user
end

def strict_mode?
  FeatureFlag.strict_mode_enabled?
end

attr_reader :user

define_link :fetch_emails do |payload|
  if user.email_addresses.count.zero? && strict_mode?
    [:error, { user: "no email addresses found", id: { user.id } }]
  else
    [:ok, { emails: user.email_addresses }]
  end
end
```
