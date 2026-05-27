import gleam/option.{type Option}
import plinth/javascript/storage

pub fn get(key: String) -> Option(String) {
  case storage.local() {
    Error(_) -> option.None
    Ok(store) ->
      case storage.get_item(store, key) {
        Error(_) -> option.None
        Ok(value) -> option.Some(value)
      }
  }
}

pub fn set(key: String, value: String) -> Nil {
  case storage.local() {
    Error(_) -> Nil
    Ok(store) -> {
      let _ = storage.set_item(store, key, value)
      Nil
    }
  }
}

pub fn remove(key: String) -> Nil {
  case storage.local() {
    Error(_) -> Nil
    Ok(store) -> storage.remove_item(store, key)
  }
}
