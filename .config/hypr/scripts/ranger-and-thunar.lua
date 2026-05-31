local ws2_arranged = false





hl.on("window.open", function(w)
    if ws2_arranged then return end

    if w.initial_class == "workspace2-thunar" then
        ws2_arranged = true
        hl.dispatch(hl.dsp.focus({ window = "initialclass:^kitty-ranger$" }))
    end
end)
