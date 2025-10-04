struct ParseError <: IonicEfus.EfusError
    message::String
    location::Location
end
