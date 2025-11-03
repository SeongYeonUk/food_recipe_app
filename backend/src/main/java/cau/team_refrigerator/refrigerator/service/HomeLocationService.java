package cau.team_refrigerator.refrigerator.service;

import cau.team_refrigerator.refrigerator.domain.HomeLocation;
import cau.team_refrigerator.refrigerator.domain.User;
import cau.team_refrigerator.refrigerator.repository.HomeLocationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

@Service
@RequiredArgsConstructor
public class HomeLocationService {

    private final HomeLocationRepository repository;

    @Transactional(readOnly = true)
    public Optional<HomeLocation> find(User user) {
        return repository.findByUser(user);
    }

    @Transactional
    public HomeLocation upsert(User user, double latitude, double longitude, Integer radius) {
        return repository.findByUser(user)
                .map(hl -> { hl.update(latitude, longitude, radius); return hl; })
                .orElseGet(() -> repository.save(new HomeLocation(user, latitude, longitude, radius != null ? radius : 100)));
    }
}

